#!/usr/bin/env bash
# cluster - group images into trips/events/sessions from the image-find TSV by
# TIME gaps + GPS proximity (macOS/Linux backend; cluster.ps1 is verified). Needs
# gawk (mktime) for the time math; on a mac install with `brew install gawk`.
#   --tsv file         image-find --tsvfile output (file order == shots order)
#   --gap-minutes N    NO-GPS (screenshots): session gap > N min -> new cluster (default 2)
#   --geo-km K         GPS: place jump > K km -> new cluster (default 2)
#   --trip-gap-hours H GPS + SAME place: time gap > H -> new cluster (default 8)
# Output: CLUSTER_COUNT=N, then per cluster (newest first):
#   CLUSTER \t id \t count \t start..end \t geo(lat,lon|-) \t reps=i,j,k \t index-ranges
set -uo pipefail

TSV=""; GAP=2; GEOKM=2; TRIPGAP=8
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) TSV="$2"; shift 2;;
    --gap-minutes) GAP="$2"; shift 2;;
    --geo-km) GEOKM="$2"; shift 2;;
    --trip-gap-hours) TRIPGAP="$2"; shift 2;;
    *) shift;;
  esac
done
[ -n "$TSV" ] && [ -f "$TSV" ] || { echo "CLUSTER_ERROR=missing --tsv"; exit 1; }
AWK="$(command -v gawk || command -v awk)"

# Pass 1: epoch \t idx \t lat \t lon  (epoch -1 if undated). Sort undated to the end.
recs="$("$AWK" -F'\t' '
  function ep(d,  y,mo,da,h,mi,s){ if (d !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}/) return -1;
    y=substr(d,1,4);mo=substr(d,6,2);da=substr(d,9,2);h=substr(d,12,2);mi=substr(d,15,2);s=substr(d,18,2);
    return (mktime(y" "mo" "da" "h" "mi" "s)) }
  { la=($5~/^-?[0-9.]+$/)?$5:""; lo=($6~/^-?[0-9.]+$/)?$6:"";
    printf "%d\t%d\t%s\t%s\n", ep($1), NR, la, lo }' "$TSV")"
sorted="$(printf '%s\n' "$recs" | awk -F'\t' '{ k=($1<0)?99999999999:$1; print k"\t"$0 }' | sort -n | cut -f2-)"

# Pass 2: segment + emit. gawk for haversine + ranges.
printf '%s\n' "$sorted" | "$AWK" -F'\t' -v gap="$GAP" -v geokm="$GEOKM" -v tripgap="$TRIPGAP" '
  function hav(la1,lo1,la2,lo2,  d,dla,dlo,a){ d=atan2(0,-1)/180; dla=(la2-la1)*d; dlo=(lo2-lo1)*d;
    a=sin(dla/2)^2+cos(la1*d)*cos(la2*d)*sin(dlo/2)^2; return 6371*2*atan2(sqrt(a),sqrt(1-a)) }
  { ep[NR]=$1; idx[NR]=$2; lat[NR]=$3; lon[NR]=$4; n=NR }
  END{
    cid=0; curgeo=0;
    for(i=1;i<=n;i++){
      brk=(i==1);
      if(!brk){
        if(lat[i]!="" && lat[i-1]!=""){
          # GPS regime: place dominates; same place tolerates a long within-trip gap.
          if(hav(lat[i-1],lon[i-1],lat[i],lon[i])>geokm) brk=1;
          else if(ep[i]>=0 && ep[i-1]>=0 && (ep[i]-ep[i-1])/3600 > tripgap) brk=1;
        } else if(curgeo){
          # Ride-along: this record has no GPS (typically a VIDEO - phone clips omit
          # GPS) but the running cluster is a GEO/trip cluster, so keep it within the
          # trip gap instead of splitting a singleton. Only a day-sized gap ends it.
          if(ep[i]>=0 && ep[i-1]>=0){ if((ep[i]-ep[i-1])/3600 > tripgap) brk=1 }
          else if((ep[i]>=0) != (ep[i-1]>=0)) brk=1;
        } else {
          # No-GPS regime: tight time-session gap.
          if(ep[i]>=0 && ep[i-1]>=0){ if((ep[i]-ep[i-1])/60 > gap) brk=1 }
          else if((ep[i]>=0) != (ep[i-1]>=0)) brk=1;
        }
      }
      if(brk){ cid++; curgeo=0; }
      cl[i]=cid; members[cid]=members[cid] (members[cid]?",":"") idx[i];
      cnt[cid]++; if(ep[i]>=0){ if(!(cid in smin)){smin[cid]=ep[i]} ; smax[cid]=ep[i] }
      # accumulate geo avg
      if(lat[i]!=""){ gla[cid]+=lat[i]; glo[cid]+=lon[i]; gn[cid]++; curgeo=1 }
      # remember member order for reps (time-sorted since input is sorted)
      ord[cid]=ord[cid] (ord[cid]?",":"") idx[i];
    }
    print "CLUSTER_COUNT=" cid;
    # newest first = reverse cluster id order (input sorted ascending by time)
    for(c=cid;c>=1;c--){
      # reps: first, middle, last of ord[c]
      m=split(ord[c],oa,","); reps=oa[1];
      if(m>=3) reps=reps","oa[int((m+1)/2)];
      if(m>=2) reps=reps","oa[m];
      span="undated";
      if(c in smin){ span=strftime("%Y-%m-%d %H:%M",smin[c]) ".." strftime("%H:%M",smax[c]) }
      geo="-"; if(gn[c]>0){ geo=sprintf("%.3f,%.3f", gla[c]/gn[c], glo[c]/gn[c]) }
      # compress members into ranges
      mm=split(members[c],ma,","); for(j=1;j<=mm;j++) num[j]=ma[j]+0;
      # sort numbers
      for(a2=1;a2<=mm;a2++) for(b2=a2+1;b2<=mm;b2++) if(num[b2]<num[a2]){t=num[a2];num[a2]=num[b2];num[b2]=t}
      rng=""; s=num[1]; p=num[1];
      for(j=2;j<=mm;j++){ if(num[j]==p+1){p=num[j]} else { rng=rng (rng?",":"") (s==p?s:s"-"p); s=num[j]; p=num[j] } }
      rng=rng (rng?",":"") (s==p?s:s"-"p);
      printf "CLUSTER\t%d\t%d\t%s\t%s\treps=%s\t%s\n", (cid-c+1), cnt[c], span, geo, reps, rng;
      delete num;
    }
  }'
