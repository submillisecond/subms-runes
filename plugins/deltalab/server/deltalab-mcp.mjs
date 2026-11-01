#!/usr/bin/env node
// deltalab MCP server. Built from subms-ui/apps/deltalab; do not edit.

// scripts/deltalab-mcp.ts
import { userInfo } from "node:os";

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/map.js
var create = () => /* @__PURE__ */ new Map();
var copy = (m) => {
  const r = create();
  m.forEach((v, k) => {
    r.set(k, v);
  });
  return r;
};
var setIfUndefined = (map3, key2, createT) => {
  let set = map3.get(key2);
  if (set === void 0) {
    map3.set(key2, set = createT());
  }
  return set;
};
var any = (m, f) => {
  for (const [key2, value] of m) {
    if (f(value, key2)) {
      return true;
    }
  }
  return false;
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/set.js
var create2 = () => /* @__PURE__ */ new Set();

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/array.js
var last = (arr) => arr[arr.length - 1];
var appendTo = (dest, src2) => {
  for (let i = 0; i < src2.length; i++) {
    dest.push(src2[i]);
  }
};
var from = Array.from;
var isArray = Array.isArray;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/observable.js
var ObservableV2 = class {
  constructor() {
    this._observers = create();
  }
  /**
   * @template {keyof EVENTS & string} NAME
   * @param {NAME} name
   * @param {EVENTS[NAME]} f
   */
  on(name, f) {
    setIfUndefined(
      this._observers,
      /** @type {string} */
      name,
      create2
    ).add(f);
    return f;
  }
  /**
   * @template {keyof EVENTS & string} NAME
   * @param {NAME} name
   * @param {EVENTS[NAME]} f
   */
  once(name, f) {
    const _f = (...args2) => {
      this.off(
        name,
        /** @type {any} */
        _f
      );
      f(...args2);
    };
    this.on(
      name,
      /** @type {any} */
      _f
    );
  }
  /**
   * @template {keyof EVENTS & string} NAME
   * @param {NAME} name
   * @param {EVENTS[NAME]} f
   */
  off(name, f) {
    const observers = this._observers.get(name);
    if (observers !== void 0) {
      observers.delete(f);
      if (observers.size === 0) {
        this._observers.delete(name);
      }
    }
  }
  /**
   * Emit a named event. All registered event listeners that listen to the
   * specified name will receive the event.
   *
   * @todo This should catch exceptions
   *
   * @template {keyof EVENTS & string} NAME
   * @param {NAME} name The event name.
   * @param {Parameters<EVENTS[NAME]>} args The arguments that are applied to the event listener.
   */
  emit(name, args2) {
    return from((this._observers.get(name) || create()).values()).forEach((f) => f(...args2));
  }
  destroy() {
    this._observers = create();
  }
};
var Observable = class {
  constructor() {
    this._observers = create();
  }
  /**
   * @param {N} name
   * @param {function} f
   */
  on(name, f) {
    setIfUndefined(this._observers, name, create2).add(f);
  }
  /**
   * @param {N} name
   * @param {function} f
   */
  once(name, f) {
    const _f = (...args2) => {
      this.off(name, _f);
      f(...args2);
    };
    this.on(name, _f);
  }
  /**
   * @param {N} name
   * @param {function} f
   */
  off(name, f) {
    const observers = this._observers.get(name);
    if (observers !== void 0) {
      observers.delete(f);
      if (observers.size === 0) {
        this._observers.delete(name);
      }
    }
  }
  /**
   * Emit a named event. All registered event listeners that listen to the
   * specified name will receive the event.
   *
   * @todo This should catch exceptions
   *
   * @param {N} name The event name.
   * @param {Array<any>} args The arguments that are applied to the event listener.
   */
  emit(name, args2) {
    return from((this._observers.get(name) || create()).values()).forEach((f) => f(...args2));
  }
  destroy() {
    this._observers = create();
  }
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/math.js
var floor = Math.floor;
var abs = Math.abs;
var min = (a, b) => a < b ? a : b;
var max = (a, b) => a > b ? a : b;
var isNaN = Number.isNaN;
var pow = Math.pow;
var isNegativeZero = (n) => n !== 0 ? n < 0 : 1 / n < 0;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/binary.js
var BIT1 = 1;
var BIT2 = 2;
var BIT3 = 4;
var BIT4 = 8;
var BIT6 = 32;
var BIT7 = 64;
var BIT8 = 128;
var BIT18 = 1 << 17;
var BIT19 = 1 << 18;
var BIT20 = 1 << 19;
var BIT21 = 1 << 20;
var BIT22 = 1 << 21;
var BIT23 = 1 << 22;
var BIT24 = 1 << 23;
var BIT25 = 1 << 24;
var BIT26 = 1 << 25;
var BIT27 = 1 << 26;
var BIT28 = 1 << 27;
var BIT29 = 1 << 28;
var BIT30 = 1 << 29;
var BIT31 = 1 << 30;
var BIT32 = 1 << 31;
var BITS5 = 31;
var BITS6 = 63;
var BITS7 = 127;
var BITS17 = BIT18 - 1;
var BITS18 = BIT19 - 1;
var BITS19 = BIT20 - 1;
var BITS20 = BIT21 - 1;
var BITS21 = BIT22 - 1;
var BITS22 = BIT23 - 1;
var BITS23 = BIT24 - 1;
var BITS24 = BIT25 - 1;
var BITS25 = BIT26 - 1;
var BITS26 = BIT27 - 1;
var BITS27 = BIT28 - 1;
var BITS28 = BIT29 - 1;
var BITS29 = BIT30 - 1;
var BITS30 = BIT31 - 1;
var BITS31 = 2147483647;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/number.js
var MAX_SAFE_INTEGER = Number.MAX_SAFE_INTEGER;
var MIN_SAFE_INTEGER = Number.MIN_SAFE_INTEGER;
var LOWEST_INT32 = 1 << 31;
var isInteger = Number.isInteger || ((num2) => typeof num2 === "number" && isFinite(num2) && floor(num2) === num2);
var isNaN2 = Number.isNaN;
var parseInt2 = Number.parseInt;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/string.js
var fromCharCode = String.fromCharCode;
var fromCodePoint = String.fromCodePoint;
var MAX_UTF16_CHARACTER = fromCharCode(65535);
var toLowerCase = (s) => s.toLowerCase();
var trimLeftRegex = /^\s*/g;
var trimLeft = (s) => s.replace(trimLeftRegex, "");
var fromCamelCaseRegex = /([A-Z])/g;
var fromCamelCase = (s, separator) => trimLeft(s.replace(fromCamelCaseRegex, (match) => `${separator}${toLowerCase(match)}`));
var _encodeUtf8Polyfill = (str2) => {
  const encodedString = unescape(encodeURIComponent(str2));
  const len = encodedString.length;
  const buf = new Uint8Array(len);
  for (let i = 0; i < len; i++) {
    buf[i] = /** @type {number} */
    encodedString.codePointAt(i);
  }
  return buf;
};
var utf8TextEncoder = (
  /** @type {TextEncoder} */
  typeof TextEncoder !== "undefined" ? new TextEncoder() : null
);
var _encodeUtf8Native = (str2) => utf8TextEncoder.encode(str2);
var encodeUtf8 = utf8TextEncoder ? _encodeUtf8Native : _encodeUtf8Polyfill;
var utf8TextDecoder = typeof TextDecoder === "undefined" ? null : new TextDecoder("utf-8", { fatal: true, ignoreBOM: true });
if (utf8TextDecoder && utf8TextDecoder.decode(new Uint8Array()).length === 1) {
  utf8TextDecoder = null;
}

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/encoding.js
var Encoder = class {
  constructor() {
    this.cpos = 0;
    this.cbuf = new Uint8Array(100);
    this.bufs = [];
  }
};
var createEncoder = () => new Encoder();
var length = (encoder) => {
  let len = encoder.cpos;
  for (let i = 0; i < encoder.bufs.length; i++) {
    len += encoder.bufs[i].length;
  }
  return len;
};
var toUint8Array = (encoder) => {
  const uint8arr = new Uint8Array(length(encoder));
  let curPos = 0;
  for (let i = 0; i < encoder.bufs.length; i++) {
    const d = encoder.bufs[i];
    uint8arr.set(d, curPos);
    curPos += d.length;
  }
  uint8arr.set(new Uint8Array(encoder.cbuf.buffer, 0, encoder.cpos), curPos);
  return uint8arr;
};
var verifyLen = (encoder, len) => {
  const bufferLen = encoder.cbuf.length;
  if (bufferLen - encoder.cpos < len) {
    encoder.bufs.push(new Uint8Array(encoder.cbuf.buffer, 0, encoder.cpos));
    encoder.cbuf = new Uint8Array(max(bufferLen, len) * 2);
    encoder.cpos = 0;
  }
};
var write = (encoder, num2) => {
  const bufferLen = encoder.cbuf.length;
  if (encoder.cpos === bufferLen) {
    encoder.bufs.push(encoder.cbuf);
    encoder.cbuf = new Uint8Array(bufferLen * 2);
    encoder.cpos = 0;
  }
  encoder.cbuf[encoder.cpos++] = num2;
};
var writeUint8 = write;
var writeVarUint = (encoder, num2) => {
  while (num2 > BITS7) {
    write(encoder, BIT8 | BITS7 & num2);
    num2 = floor(num2 / 128);
  }
  write(encoder, BITS7 & num2);
};
var writeVarInt = (encoder, num2) => {
  const isNegative = isNegativeZero(num2);
  if (isNegative) {
    num2 = -num2;
  }
  write(encoder, (num2 > BITS6 ? BIT8 : 0) | (isNegative ? BIT7 : 0) | BITS6 & num2);
  num2 = floor(num2 / 64);
  while (num2 > 0) {
    write(encoder, (num2 > BITS7 ? BIT8 : 0) | BITS7 & num2);
    num2 = floor(num2 / 128);
  }
};
var _strBuffer = new Uint8Array(3e4);
var _maxStrBSize = _strBuffer.length / 3;
var _writeVarStringNative = (encoder, str2) => {
  if (str2.length < _maxStrBSize) {
    const written = utf8TextEncoder.encodeInto(str2, _strBuffer).written || 0;
    writeVarUint(encoder, written);
    for (let i = 0; i < written; i++) {
      write(encoder, _strBuffer[i]);
    }
  } else {
    writeVarUint8Array(encoder, encodeUtf8(str2));
  }
};
var _writeVarStringPolyfill = (encoder, str2) => {
  const encodedString = unescape(encodeURIComponent(str2));
  const len = encodedString.length;
  writeVarUint(encoder, len);
  for (let i = 0; i < len; i++) {
    write(
      encoder,
      /** @type {number} */
      encodedString.codePointAt(i)
    );
  }
};
var writeVarString = utf8TextEncoder && /** @type {any} */
utf8TextEncoder.encodeInto ? _writeVarStringNative : _writeVarStringPolyfill;
var writeUint8Array = (encoder, uint8Array) => {
  const bufferLen = encoder.cbuf.length;
  const cpos = encoder.cpos;
  const leftCopyLen = min(bufferLen - cpos, uint8Array.length);
  const rightCopyLen = uint8Array.length - leftCopyLen;
  encoder.cbuf.set(uint8Array.subarray(0, leftCopyLen), cpos);
  encoder.cpos += leftCopyLen;
  if (rightCopyLen > 0) {
    encoder.bufs.push(encoder.cbuf);
    encoder.cbuf = new Uint8Array(max(bufferLen * 2, rightCopyLen));
    encoder.cbuf.set(uint8Array.subarray(leftCopyLen));
    encoder.cpos = rightCopyLen;
  }
};
var writeVarUint8Array = (encoder, uint8Array) => {
  writeVarUint(encoder, uint8Array.byteLength);
  writeUint8Array(encoder, uint8Array);
};
var writeOnDataView = (encoder, len) => {
  verifyLen(encoder, len);
  const dview = new DataView(encoder.cbuf.buffer, encoder.cpos, len);
  encoder.cpos += len;
  return dview;
};
var writeFloat32 = (encoder, num2) => writeOnDataView(encoder, 4).setFloat32(0, num2, false);
var writeFloat64 = (encoder, num2) => writeOnDataView(encoder, 8).setFloat64(0, num2, false);
var writeBigInt64 = (encoder, num2) => (
  /** @type {any} */
  writeOnDataView(encoder, 8).setBigInt64(0, num2, false)
);
var floatTestBed = new DataView(new ArrayBuffer(4));
var isFloat32 = (num2) => {
  floatTestBed.setFloat32(0, num2);
  return floatTestBed.getFloat32(0) === num2;
};
var writeAny = (encoder, data) => {
  switch (typeof data) {
    case "string":
      write(encoder, 119);
      writeVarString(encoder, data);
      break;
    case "number":
      if (isInteger(data) && abs(data) <= BITS31) {
        write(encoder, 125);
        writeVarInt(encoder, data);
      } else if (isFloat32(data)) {
        write(encoder, 124);
        writeFloat32(encoder, data);
      } else {
        write(encoder, 123);
        writeFloat64(encoder, data);
      }
      break;
    case "bigint":
      write(encoder, 122);
      writeBigInt64(encoder, data);
      break;
    case "object":
      if (data === null) {
        write(encoder, 126);
      } else if (isArray(data)) {
        write(encoder, 117);
        writeVarUint(encoder, data.length);
        for (let i = 0; i < data.length; i++) {
          writeAny(encoder, data[i]);
        }
      } else if (data instanceof Uint8Array) {
        write(encoder, 116);
        writeVarUint8Array(encoder, data);
      } else {
        write(encoder, 118);
        const keys2 = Object.keys(data);
        writeVarUint(encoder, keys2.length);
        for (let i = 0; i < keys2.length; i++) {
          const key2 = keys2[i];
          writeVarString(encoder, key2);
          writeAny(encoder, data[key2]);
        }
      }
      break;
    case "boolean":
      write(encoder, data ? 120 : 121);
      break;
    default:
      write(encoder, 127);
  }
};
var RleEncoder = class extends Encoder {
  /**
   * @param {function(Encoder, T):void} writer
   */
  constructor(writer) {
    super();
    this.w = writer;
    this.s = null;
    this.count = 0;
  }
  /**
   * @param {T} v
   */
  write(v) {
    if (this.s === v) {
      this.count++;
    } else {
      if (this.count > 0) {
        writeVarUint(this, this.count - 1);
      }
      this.count = 1;
      this.w(this, v);
      this.s = v;
    }
  }
};
var flushUintOptRleEncoder = (encoder) => {
  if (encoder.count > 0) {
    writeVarInt(encoder.encoder, encoder.count === 1 ? encoder.s : -encoder.s);
    if (encoder.count > 1) {
      writeVarUint(encoder.encoder, encoder.count - 2);
    }
  }
};
var UintOptRleEncoder = class {
  constructor() {
    this.encoder = new Encoder();
    this.s = 0;
    this.count = 0;
  }
  /**
   * @param {number} v
   */
  write(v) {
    if (this.s === v) {
      this.count++;
    } else {
      flushUintOptRleEncoder(this);
      this.count = 1;
      this.s = v;
    }
  }
  /**
   * Flush the encoded state and transform this to a Uint8Array.
   *
   * Note that this should only be called once.
   */
  toUint8Array() {
    flushUintOptRleEncoder(this);
    return toUint8Array(this.encoder);
  }
};
var flushIntDiffOptRleEncoder = (encoder) => {
  if (encoder.count > 0) {
    const encodedDiff = encoder.diff * 2 + (encoder.count === 1 ? 0 : 1);
    writeVarInt(encoder.encoder, encodedDiff);
    if (encoder.count > 1) {
      writeVarUint(encoder.encoder, encoder.count - 2);
    }
  }
};
var IntDiffOptRleEncoder = class {
  constructor() {
    this.encoder = new Encoder();
    this.s = 0;
    this.count = 0;
    this.diff = 0;
  }
  /**
   * @param {number} v
   */
  write(v) {
    if (this.diff === v - this.s) {
      this.s = v;
      this.count++;
    } else {
      flushIntDiffOptRleEncoder(this);
      this.count = 1;
      this.diff = v - this.s;
      this.s = v;
    }
  }
  /**
   * Flush the encoded state and transform this to a Uint8Array.
   *
   * Note that this should only be called once.
   */
  toUint8Array() {
    flushIntDiffOptRleEncoder(this);
    return toUint8Array(this.encoder);
  }
};
var StringEncoder = class {
  constructor() {
    this.sarr = [];
    this.s = "";
    this.lensE = new UintOptRleEncoder();
  }
  /**
   * @param {string} string
   */
  write(string) {
    this.s += string;
    if (this.s.length > 19) {
      this.sarr.push(this.s);
      this.s = "";
    }
    this.lensE.write(string.length);
  }
  toUint8Array() {
    const encoder = new Encoder();
    this.sarr.push(this.s);
    this.s = "";
    writeVarString(encoder, this.sarr.join(""));
    writeUint8Array(encoder, this.lensE.toUint8Array());
    return toUint8Array(encoder);
  }
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/error.js
var create3 = (s) => new Error(s);
var methodUnimplemented = () => {
  throw create3("Method unimplemented");
};
var unexpectedCase = () => {
  throw create3("Unexpected case");
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/decoding.js
var errorUnexpectedEndOfArray = create3("Unexpected end of array");
var errorIntegerOutOfRange = create3("Integer out of Range");
var Decoder = class {
  /**
   * @param {Uint8Array<Buf>} uint8Array Binary data to decode
   */
  constructor(uint8Array) {
    this.arr = uint8Array;
    this.pos = 0;
  }
};
var createDecoder = (uint8Array) => new Decoder(uint8Array);
var hasContent = (decoder) => decoder.pos !== decoder.arr.length;
var readUint8Array = (decoder, len) => {
  const view = new Uint8Array(decoder.arr.buffer, decoder.pos + decoder.arr.byteOffset, len);
  decoder.pos += len;
  return view;
};
var readVarUint8Array = (decoder) => readUint8Array(decoder, readVarUint(decoder));
var readUint8 = (decoder) => decoder.arr[decoder.pos++];
var readVarUint = (decoder) => {
  let num2 = 0;
  let mult = 1;
  const len = decoder.arr.length;
  while (decoder.pos < len) {
    const r = decoder.arr[decoder.pos++];
    num2 = num2 + (r & BITS7) * mult;
    mult *= 128;
    if (r < BIT8) {
      return num2;
    }
    if (num2 > MAX_SAFE_INTEGER) {
      throw errorIntegerOutOfRange;
    }
  }
  throw errorUnexpectedEndOfArray;
};
var readVarInt = (decoder) => {
  let r = decoder.arr[decoder.pos++];
  let num2 = r & BITS6;
  let mult = 64;
  const sign2 = (r & BIT7) > 0 ? -1 : 1;
  if ((r & BIT8) === 0) {
    return sign2 * num2;
  }
  const len = decoder.arr.length;
  while (decoder.pos < len) {
    r = decoder.arr[decoder.pos++];
    num2 = num2 + (r & BITS7) * mult;
    mult *= 128;
    if (r < BIT8) {
      return sign2 * num2;
    }
    if (num2 > MAX_SAFE_INTEGER) {
      throw errorIntegerOutOfRange;
    }
  }
  throw errorUnexpectedEndOfArray;
};
var _readVarStringPolyfill = (decoder) => {
  let remainingLen = readVarUint(decoder);
  if (remainingLen === 0) {
    return "";
  } else {
    let encodedString = String.fromCodePoint(readUint8(decoder));
    if (--remainingLen < 100) {
      while (remainingLen--) {
        encodedString += String.fromCodePoint(readUint8(decoder));
      }
    } else {
      while (remainingLen > 0) {
        const nextLen = remainingLen < 1e4 ? remainingLen : 1e4;
        const bytes = decoder.arr.subarray(decoder.pos, decoder.pos + nextLen);
        decoder.pos += nextLen;
        encodedString += String.fromCodePoint.apply(
          null,
          /** @type {any} */
          bytes
        );
        remainingLen -= nextLen;
      }
    }
    return decodeURIComponent(escape(encodedString));
  }
};
var _readVarStringNative = (decoder) => (
  /** @type any */
  utf8TextDecoder.decode(readVarUint8Array(decoder))
);
var readVarString = utf8TextDecoder ? _readVarStringNative : _readVarStringPolyfill;
var readFromDataView = (decoder, len) => {
  const dv = new DataView(decoder.arr.buffer, decoder.arr.byteOffset + decoder.pos, len);
  decoder.pos += len;
  return dv;
};
var readFloat32 = (decoder) => readFromDataView(decoder, 4).getFloat32(0, false);
var readFloat64 = (decoder) => readFromDataView(decoder, 8).getFloat64(0, false);
var readBigInt64 = (decoder) => (
  /** @type {any} */
  readFromDataView(decoder, 8).getBigInt64(0, false)
);
var readAnyLookupTable = [
  (decoder) => void 0,
  // CASE 127: undefined
  (decoder) => null,
  // CASE 126: null
  readVarInt,
  // CASE 125: integer
  readFloat32,
  // CASE 124: float32
  readFloat64,
  // CASE 123: float64
  readBigInt64,
  // CASE 122: bigint
  (decoder) => false,
  // CASE 121: boolean (false)
  (decoder) => true,
  // CASE 120: boolean (true)
  readVarString,
  // CASE 119: string
  (decoder) => {
    const len = readVarUint(decoder);
    const obj = {};
    for (let i = 0; i < len; i++) {
      const key2 = readVarString(decoder);
      obj[key2] = readAny(decoder);
    }
    return obj;
  },
  (decoder) => {
    const len = readVarUint(decoder);
    const arr = [];
    for (let i = 0; i < len; i++) {
      arr.push(readAny(decoder));
    }
    return arr;
  },
  readVarUint8Array
  // CASE 116: Uint8Array
];
var readAny = (decoder) => readAnyLookupTable[127 - readUint8(decoder)](decoder);
var RleDecoder = class extends Decoder {
  /**
   * @param {Uint8Array} uint8Array
   * @param {function(Decoder):T} reader
   */
  constructor(uint8Array, reader) {
    super(uint8Array);
    this.reader = reader;
    this.s = null;
    this.count = 0;
  }
  read() {
    if (this.count === 0) {
      this.s = this.reader(this);
      if (hasContent(this)) {
        this.count = readVarUint(this) + 1;
      } else {
        this.count = -1;
      }
    }
    this.count--;
    return (
      /** @type {T} */
      this.s
    );
  }
};
var UintOptRleDecoder = class extends Decoder {
  /**
   * @param {Uint8Array} uint8Array
   */
  constructor(uint8Array) {
    super(uint8Array);
    this.s = 0;
    this.count = 0;
  }
  read() {
    if (this.count === 0) {
      this.s = readVarInt(this);
      const isNegative = isNegativeZero(this.s);
      this.count = 1;
      if (isNegative) {
        this.s = -this.s;
        this.count = readVarUint(this) + 2;
      }
    }
    this.count--;
    return (
      /** @type {number} */
      this.s
    );
  }
};
var IntDiffOptRleDecoder = class extends Decoder {
  /**
   * @param {Uint8Array} uint8Array
   */
  constructor(uint8Array) {
    super(uint8Array);
    this.s = 0;
    this.count = 0;
    this.diff = 0;
  }
  /**
   * @return {number}
   */
  read() {
    if (this.count === 0) {
      const diff = readVarInt(this);
      const hasCount = diff & 1;
      this.diff = floor(diff / 2);
      this.count = 1;
      if (hasCount) {
        this.count = readVarUint(this) + 2;
      }
    }
    this.s += this.diff;
    this.count--;
    return this.s;
  }
};
var StringDecoder = class {
  /**
   * @param {Uint8Array} uint8Array
   */
  constructor(uint8Array) {
    this.decoder = new UintOptRleDecoder(uint8Array);
    this.str = readVarString(this.decoder);
    this.spos = 0;
  }
  /**
   * @return {string}
   */
  read() {
    const end = this.spos + this.decoder.read();
    const res = this.str.slice(this.spos, end);
    this.spos = end;
    return res;
  }
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/webcrypto.node.js
import { webcrypto } from "node:crypto";
var subtle = (
  /** @type {any} */
  webcrypto.subtle
);
var getRandomValues = (
  /** @type {any} */
  webcrypto.getRandomValues.bind(webcrypto)
);

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/random.js
var uint32 = () => getRandomValues(new Uint32Array(1))[0];
var uuidv4Template = "10000000-1000-4000-8000" + -1e11;
var uuidv4 = () => uuidv4Template.replace(
  /[018]/g,
  /** @param {number} c */
  (c) => (c ^ uint32() & 15 >> c / 4).toString(16)
);

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/time.js
var getUnixTime = Date.now;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/promise.js
var create4 = (f) => (
  /** @type {Promise<T>} */
  new Promise(f)
);
var all = Promise.all.bind(Promise);

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/conditions.js
var undefinedToNull = (v) => v === void 0 ? null : v;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/storage.js
var VarStoragePolyfill = class {
  constructor() {
    this.map = /* @__PURE__ */ new Map();
  }
  /**
   * @param {string} key
   * @param {any} newValue
   */
  setItem(key2, newValue) {
    this.map.set(key2, newValue);
  }
  /**
   * @param {string} key
   */
  getItem(key2) {
    return this.map.get(key2);
  }
};
var _localStorage = new VarStoragePolyfill();
var usePolyfill = true;
try {
  if (typeof localStorage !== "undefined" && localStorage) {
    _localStorage = localStorage;
    usePolyfill = false;
  }
} catch (e) {
}
var varStorage = _localStorage;
var onChange = (eventHandler) => usePolyfill || addEventListener(
  "storage",
  /** @type {any} */
  eventHandler
);
var offChange = (eventHandler) => usePolyfill || removeEventListener(
  "storage",
  /** @type {any} */
  eventHandler
);

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/trait/equality.js
var EqualityTraitSymbol = Symbol("Equality");
var equals = (a, b) => a === b || !!a?.[EqualityTraitSymbol]?.(b) || false;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/object.js
var assign = Object.assign;
var keys = Object.keys;
var forEach = (obj, f) => {
  for (const key2 in obj) {
    f(obj[key2], key2);
  }
};
var map = (obj, f) => {
  const results = [];
  for (const key2 in obj) {
    results.push(f(obj[key2], key2));
  }
  return results;
};
var size = (obj) => keys(obj).length;
var isEmpty = (obj) => {
  for (const _k in obj) {
    return false;
  }
  return true;
};
var every = (obj, f) => {
  for (const key2 in obj) {
    if (!f(obj[key2], key2)) {
      return false;
    }
  }
  return true;
};
var hasProperty = (obj, key2) => Object.prototype.hasOwnProperty.call(obj, key2);
var equalFlat = (a, b) => a === b || size(a) === size(b) && every(a, (val, key2) => (val !== void 0 || hasProperty(b, key2)) && equals(b[key2], val));
var freeze = Object.freeze;
var deepFreeze = (o) => {
  for (const key2 in o) {
    const c = o[key2];
    if (typeof c === "object" || typeof c === "function") {
      deepFreeze(o[key2]);
    }
  }
  return freeze(o);
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/function.js
var callAll = (fs, args2, i = 0) => {
  try {
    for (; i < fs.length; i++) {
      fs[i](...args2);
    }
  } finally {
    if (i < fs.length) {
      callAll(fs, args2, i + 1);
    }
  }
};
var id = (a) => a;
var equalityDeep = (a, b) => {
  if (a === b) {
    return true;
  }
  if (a == null || b == null || a.constructor !== b.constructor && (a.constructor || Object) !== (b.constructor || Object)) {
    return false;
  }
  if (a[EqualityTraitSymbol] != null) {
    return a[EqualityTraitSymbol](b);
  }
  switch (a.constructor) {
    case ArrayBuffer:
      a = new Uint8Array(a);
      b = new Uint8Array(b);
    // eslint-disable-next-line no-fallthrough
    case Uint8Array: {
      if (a.byteLength !== b.byteLength) {
        return false;
      }
      for (let i = 0; i < a.length; i++) {
        if (a[i] !== b[i]) {
          return false;
        }
      }
      break;
    }
    case Set: {
      if (a.size !== b.size) {
        return false;
      }
      for (const value of a) {
        if (!b.has(value)) {
          return false;
        }
      }
      break;
    }
    case Map: {
      if (a.size !== b.size) {
        return false;
      }
      for (const key2 of a.keys()) {
        if (!b.has(key2) || !equalityDeep(a.get(key2), b.get(key2))) {
          return false;
        }
      }
      break;
    }
    case void 0:
    case Object:
      if (size(a) !== size(b)) {
        return false;
      }
      for (const key2 in a) {
        if (!hasProperty(a, key2) || !equalityDeep(a[key2], b[key2])) {
          return false;
        }
      }
      break;
    case Array:
      if (a.length !== b.length) {
        return false;
      }
      for (let i = 0; i < a.length; i++) {
        if (!equalityDeep(a[i], b[i])) {
          return false;
        }
      }
      break;
    default:
      return false;
  }
  return true;
};
var isOneOf = (value, options) => options.includes(value);

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/environment.js
var isNode = typeof process !== "undefined" && process.release && /node|io\.js/.test(process.release.name) && Object.prototype.toString.call(typeof process !== "undefined" ? process : 0) === "[object process]";
var isBrowser = typeof window !== "undefined" && typeof document !== "undefined" && !isNode;
var isMac = typeof navigator !== "undefined" ? /Mac/.test(navigator.platform) : false;
var params;
var args = [];
var computeParams = () => {
  if (params === void 0) {
    if (isNode) {
      params = create();
      const pargs = process.argv;
      let currParamName = null;
      for (let i = 0; i < pargs.length; i++) {
        const parg = pargs[i];
        if (parg[0] === "-") {
          if (currParamName !== null) {
            params.set(currParamName, "");
          }
          currParamName = parg;
        } else {
          if (currParamName !== null) {
            params.set(currParamName, parg);
            currParamName = null;
          } else {
            args.push(parg);
          }
        }
      }
      if (currParamName !== null) {
        params.set(currParamName, "");
      }
    } else if (typeof location === "object") {
      params = create();
      (location.search || "?").slice(1).split("&").forEach((kv) => {
        if (kv.length !== 0) {
          const [key2, value] = kv.split("=");
          params.set(`--${fromCamelCase(key2, "-")}`, value);
          params.set(`-${fromCamelCase(key2, "-")}`, value);
        }
      });
    } else {
      params = create();
    }
  }
  return params;
};
var hasParam = (name) => computeParams().has(name);
var getVariable = (name) => isNode ? undefinedToNull(process.env[name.toUpperCase().replaceAll("-", "_")]) : undefinedToNull(varStorage.getItem(name));
var hasConf = (name) => hasParam("--" + name) || getVariable(name) !== null;
var production = hasConf("production");
var forceColor = isNode && isOneOf(process.env.FORCE_COLOR, ["true", "1", "2"]);
var supportsColor = forceColor || !hasParam("--no-colors") && // @todo deprecate --no-colors
!hasConf("no-color") && (!isNode || process.stdout.isTTY) && (!isNode || hasParam("--color") || getVariable("COLORTERM") !== null || (getVariable("TERM") || "").includes("color"));

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/buffer.js
var createUint8ArrayFromLen = (len) => new Uint8Array(len);
var createUint8ArrayViewFromArrayBuffer = (buffer, byteOffset, length2) => new Uint8Array(buffer, byteOffset, length2);
var createUint8ArrayFromArrayBuffer = (buffer) => new Uint8Array(buffer);
var toBase64Browser = (bytes) => {
  let s = "";
  for (let i = 0; i < bytes.byteLength; i++) {
    s += fromCharCode(bytes[i]);
  }
  return btoa(s);
};
var toBase64Node = (bytes) => Buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString("base64");
var fromBase64Browser = (s) => {
  const a = atob(s);
  const bytes = createUint8ArrayFromLen(a.length);
  for (let i = 0; i < a.length; i++) {
    bytes[i] = a.charCodeAt(i);
  }
  return bytes;
};
var fromBase64Node = (s) => {
  const buf = Buffer.from(s, "base64");
  return createUint8ArrayViewFromArrayBuffer(buf.buffer, buf.byteOffset, buf.byteLength);
};
var toBase64 = isBrowser ? toBase64Browser : toBase64Node;
var fromBase64 = isBrowser ? fromBase64Browser : fromBase64Node;
var copyUint8Array = (uint8Array) => {
  const newBuf = createUint8ArrayFromLen(uint8Array.byteLength);
  newBuf.set(uint8Array);
  return newBuf;
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/symbol.js
var create5 = Symbol;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/logging.common.js
var BOLD = create5();
var UNBOLD = create5();
var BLUE = create5();
var GREY = create5();
var GREEN = create5();
var RED = create5();
var PURPLE = create5();
var ORANGE = create5();
var UNCOLOR = create5();
var computeNoColorLoggingArgs = (args2) => {
  if (args2.length === 1 && args2[0]?.constructor === Function) {
    args2 = /** @type {Array<string|Symbol|Object|number>} */
    /** @type {[function]} */
    args2[0]();
  }
  const strBuilder = [];
  const logArgs = [];
  let i = 0;
  for (; i < args2.length; i++) {
    const arg = args2[i];
    if (arg === void 0) {
      break;
    } else if (arg.constructor === String || arg.constructor === Number) {
      strBuilder.push(arg);
    } else if (arg.constructor === Object) {
      break;
    }
  }
  if (i > 0) {
    logArgs.push(strBuilder.join(""));
  }
  for (; i < args2.length; i++) {
    const arg = args2[i];
    if (!(arg instanceof Symbol)) {
      logArgs.push(arg);
    }
  }
  return logArgs;
};
var lastLoggingTime = getUnixTime();

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/logging.node.js
var _nodeStyleMap = {
  [BOLD]: "\x1B[1m",
  [UNBOLD]: "\x1B[2m",
  [BLUE]: "\x1B[34m",
  [GREEN]: "\x1B[32m",
  [GREY]: "\x1B[37m",
  [RED]: "\x1B[31m",
  [PURPLE]: "\x1B[35m",
  [ORANGE]: "\x1B[38;5;208m",
  [UNCOLOR]: "\x1B[0m"
};
var computeNodeLoggingArgs = (args2) => {
  if (args2.length === 1 && args2[0]?.constructor === Function) {
    args2 = /** @type {Array<string|Symbol|Object|number>} */
    /** @type {[function]} */
    args2[0]();
  }
  const strBuilder = [];
  const logArgs = [];
  let i = 0;
  for (; i < args2.length; i++) {
    const arg = args2[i];
    const style = _nodeStyleMap[arg];
    if (style !== void 0) {
      strBuilder.push(style);
    } else {
      if (arg === void 0) {
        break;
      } else if (arg.constructor === String || arg.constructor === Number) {
        strBuilder.push(arg);
      } else {
        break;
      }
    }
  }
  if (i > 0) {
    strBuilder.push("\x1B[0m");
    logArgs.push(strBuilder.join(""));
  }
  for (; i < args2.length; i++) {
    const arg = args2[i];
    if (!(arg instanceof Symbol)) {
      logArgs.push(arg);
    }
  }
  return logArgs;
};
var computeLoggingArgs = supportsColor ? computeNodeLoggingArgs : computeNoColorLoggingArgs;
var print = (...args2) => {
  console.log(...computeLoggingArgs(args2));
};
var warn = (...args2) => {
  console.warn(...computeLoggingArgs(args2));
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/iterator.js
var createIterator = (next) => ({
  /**
   * @return {IterableIterator<T>}
   */
  [Symbol.iterator]() {
    return this;
  },
  // @ts-ignore
  next
});
var iteratorFilter = (iterator, filter) => createIterator(() => {
  let res;
  do {
    res = iterator.next();
  } while (!res.done && !filter(res.value));
  return res;
});
var iteratorMap = (iterator, fmap) => createIterator(() => {
  const { done, value } = iterator.next();
  return { done, value: done ? void 0 : fmap(value) };
});

// ../../node_modules/.pnpm/yjs@13.6.31/node_modules/yjs/dist/yjs.mjs
var DeleteItem = class {
  /**
   * @param {number} clock
   * @param {number} len
   */
  constructor(clock, len) {
    this.clock = clock;
    this.len = len;
  }
};
var DeleteSet = class {
  constructor() {
    this.clients = /* @__PURE__ */ new Map();
  }
};
var iterateDeletedStructs = (transaction, ds, f) => ds.clients.forEach((deletes, clientid) => {
  const structs = (
    /** @type {Array<GC|Item>} */
    transaction.doc.store.clients.get(clientid)
  );
  if (structs != null) {
    const lastStruct = structs[structs.length - 1];
    const clockState = lastStruct.id.clock + lastStruct.length;
    for (let i = 0, del = deletes[i]; i < deletes.length && del.clock < clockState; del = deletes[++i]) {
      iterateStructs(transaction, structs, del.clock, del.len, f);
    }
  }
});
var findIndexDS = (dis, clock) => {
  let left = 0;
  let right = dis.length - 1;
  while (left <= right) {
    const midindex = floor((left + right) / 2);
    const mid = dis[midindex];
    const midclock = mid.clock;
    if (midclock <= clock) {
      if (clock < midclock + mid.len) {
        return midindex;
      }
      left = midindex + 1;
    } else {
      right = midindex - 1;
    }
  }
  return null;
};
var isDeleted = (ds, id2) => {
  const dis = ds.clients.get(id2.client);
  return dis !== void 0 && findIndexDS(dis, id2.clock) !== null;
};
var sortAndMergeDeleteSet = (ds) => {
  ds.clients.forEach((dels) => {
    dels.sort((a, b) => a.clock - b.clock);
    let i, j;
    for (i = 1, j = 1; i < dels.length; i++) {
      const left = dels[j - 1];
      const right = dels[i];
      if (left.clock + left.len >= right.clock) {
        dels[j - 1] = new DeleteItem(left.clock, max(left.len, right.clock + right.len - left.clock));
      } else {
        if (j < i) {
          dels[j] = right;
        }
        j++;
      }
    }
    dels.length = j;
  });
};
var mergeDeleteSets = (dss) => {
  const merged = new DeleteSet();
  for (let dssI = 0; dssI < dss.length; dssI++) {
    dss[dssI].clients.forEach((delsLeft, client) => {
      if (!merged.clients.has(client)) {
        const dels = delsLeft.slice();
        for (let i = dssI + 1; i < dss.length; i++) {
          appendTo(dels, dss[i].clients.get(client) || []);
        }
        merged.clients.set(client, dels);
      }
    });
  }
  sortAndMergeDeleteSet(merged);
  return merged;
};
var addToDeleteSet = (ds, client, clock, length2) => {
  setIfUndefined(ds.clients, client, () => (
    /** @type {Array<DeleteItem>} */
    []
  )).push(new DeleteItem(clock, length2));
};
var createDeleteSet = () => new DeleteSet();
var createDeleteSetFromStructStore = (ss) => {
  const ds = createDeleteSet();
  ss.clients.forEach((structs, client) => {
    const dsitems = [];
    for (let i = 0; i < structs.length; i++) {
      const struct = structs[i];
      if (struct.deleted) {
        const clock = struct.id.clock;
        let len = struct.length;
        if (i + 1 < structs.length) {
          for (let next = structs[i + 1]; i + 1 < structs.length && next.deleted; next = structs[++i + 1]) {
            len += next.length;
          }
        }
        dsitems.push(new DeleteItem(clock, len));
      }
    }
    if (dsitems.length > 0) {
      ds.clients.set(client, dsitems);
    }
  });
  return ds;
};
var writeDeleteSet = (encoder, ds) => {
  writeVarUint(encoder.restEncoder, ds.clients.size);
  from(ds.clients.entries()).sort((a, b) => b[0] - a[0]).forEach(([client, dsitems]) => {
    encoder.resetDsCurVal();
    writeVarUint(encoder.restEncoder, client);
    const len = dsitems.length;
    writeVarUint(encoder.restEncoder, len);
    for (let i = 0; i < len; i++) {
      const item = dsitems[i];
      encoder.writeDsClock(item.clock);
      encoder.writeDsLen(item.len);
    }
  });
};
var readDeleteSet = (decoder) => {
  const ds = new DeleteSet();
  const numClients = readVarUint(decoder.restDecoder);
  for (let i = 0; i < numClients; i++) {
    decoder.resetDsCurVal();
    const client = readVarUint(decoder.restDecoder);
    const numberOfDeletes = readVarUint(decoder.restDecoder);
    if (numberOfDeletes > 0) {
      const dsField = setIfUndefined(ds.clients, client, () => (
        /** @type {Array<DeleteItem>} */
        []
      ));
      for (let i2 = 0; i2 < numberOfDeletes; i2++) {
        dsField.push(new DeleteItem(decoder.readDsClock(), decoder.readDsLen()));
      }
    }
  }
  return ds;
};
var readAndApplyDeleteSet = (decoder, transaction, store) => {
  const unappliedDS = new DeleteSet();
  const numClients = readVarUint(decoder.restDecoder);
  for (let i = 0; i < numClients; i++) {
    decoder.resetDsCurVal();
    const client = readVarUint(decoder.restDecoder);
    const numberOfDeletes = readVarUint(decoder.restDecoder);
    const structs = store.clients.get(client) || [];
    const state = getState(store, client);
    for (let i2 = 0; i2 < numberOfDeletes; i2++) {
      const clock = decoder.readDsClock();
      const clockEnd = clock + decoder.readDsLen();
      if (clock < state) {
        if (state < clockEnd) {
          addToDeleteSet(unappliedDS, client, state, clockEnd - state);
        }
        let index = findIndexSS(structs, clock);
        let struct = structs[index];
        if (!struct.deleted && struct.id.clock < clock) {
          structs.splice(index + 1, 0, splitItem(transaction, struct, clock - struct.id.clock));
          index++;
        }
        while (index < structs.length) {
          struct = structs[index++];
          if (struct.id.clock < clockEnd) {
            if (!struct.deleted) {
              if (clockEnd < struct.id.clock + struct.length) {
                structs.splice(index, 0, splitItem(transaction, struct, clockEnd - struct.id.clock));
              }
              struct.delete(transaction);
            }
          } else {
            break;
          }
        }
      } else {
        addToDeleteSet(unappliedDS, client, clock, clockEnd - clock);
      }
    }
  }
  if (unappliedDS.clients.size > 0) {
    const ds = new UpdateEncoderV2();
    writeVarUint(ds.restEncoder, 0);
    writeDeleteSet(ds, unappliedDS);
    return ds.toUint8Array();
  }
  return null;
};
var generateNewClientId = uint32;
var Doc = class _Doc extends ObservableV2 {
  /**
   * @param {DocOpts} opts configuration
   */
  constructor({ guid = uuidv4(), collectionid = null, gc = true, gcFilter = () => true, meta = null, autoLoad = false, shouldLoad = true } = {}) {
    super();
    this.gc = gc;
    this.gcFilter = gcFilter;
    this.clientID = generateNewClientId();
    this.guid = guid;
    this.collectionid = collectionid;
    this.share = /* @__PURE__ */ new Map();
    this.store = new StructStore();
    this._transaction = null;
    this._transactionCleanups = [];
    this.subdocs = /* @__PURE__ */ new Set();
    this._item = null;
    this.shouldLoad = shouldLoad;
    this.autoLoad = autoLoad;
    this.meta = meta;
    this.isLoaded = false;
    this.isSynced = false;
    this.isDestroyed = false;
    this.whenLoaded = create4((resolve) => {
      this.on("load", () => {
        this.isLoaded = true;
        resolve(this);
      });
    });
    const provideSyncedPromise = () => create4((resolve) => {
      const eventHandler = (isSynced) => {
        if (isSynced === void 0 || isSynced === true) {
          this.off("sync", eventHandler);
          resolve();
        }
      };
      this.on("sync", eventHandler);
    });
    this.on("sync", (isSynced) => {
      if (isSynced === false && this.isSynced) {
        this.whenSynced = provideSyncedPromise();
      }
      this.isSynced = isSynced === void 0 || isSynced === true;
      if (this.isSynced && !this.isLoaded) {
        this.emit("load", [this]);
      }
    });
    this.whenSynced = provideSyncedPromise();
  }
  /**
   * Notify the parent document that you request to load data into this subdocument (if it is a subdocument).
   *
   * `load()` might be used in the future to request any provider to load the most current data.
   *
   * It is safe to call `load()` multiple times.
   */
  load() {
    const item = this._item;
    if (item !== null && !this.shouldLoad) {
      transact(
        /** @type {any} */
        item.parent.doc,
        (transaction) => {
          transaction.subdocsLoaded.add(this);
        },
        null,
        true
      );
    }
    this.shouldLoad = true;
  }
  getSubdocs() {
    return this.subdocs;
  }
  getSubdocGuids() {
    return new Set(from(this.subdocs).map((doc) => doc.guid));
  }
  /**
   * Changes that happen inside of a transaction are bundled. This means that
   * the observer fires _after_ the transaction is finished and that all changes
   * that happened inside of the transaction are sent as one message to the
   * other peers.
   *
   * @template T
   * @param {function(Transaction):T} f The function that should be executed as a transaction
   * @param {any} [origin] Origin of who started the transaction. Will be stored on transaction.origin
   * @return T
   *
   * @public
   */
  transact(f, origin = null) {
    return transact(this, f, origin);
  }
  /**
   * Define a shared data type.
   *
   * Multiple calls of `ydoc.get(name, TypeConstructor)` yield the same result
   * and do not overwrite each other. I.e.
   * `ydoc.get(name, Y.Array) === ydoc.get(name, Y.Array)`
   *
   * After this method is called, the type is also available on `ydoc.share.get(name)`.
   *
   * *Best Practices:*
   * Define all types right after the Y.Doc instance is created and store them in a separate object.
   * Also use the typed methods `getText(name)`, `getArray(name)`, ..
   *
   * @template {typeof AbstractType<any>} Type
   * @example
   *   const ydoc = new Y.Doc(..)
   *   const appState = {
   *     document: ydoc.getText('document')
   *     comments: ydoc.getArray('comments')
   *   }
   *
   * @param {string} name
   * @param {Type} TypeConstructor The constructor of the type definition. E.g. Y.Text, Y.Array, Y.Map, ...
   * @return {InstanceType<Type>} The created type. Constructed with TypeConstructor
   *
   * @public
   */
  get(name, TypeConstructor = (
    /** @type {any} */
    AbstractType
  )) {
    const type = setIfUndefined(this.share, name, () => {
      const t = new TypeConstructor();
      t._integrate(this, null);
      return t;
    });
    const Constr = type.constructor;
    if (TypeConstructor !== AbstractType && Constr !== TypeConstructor) {
      if (Constr === AbstractType) {
        const t = new TypeConstructor();
        t._map = type._map;
        type._map.forEach(
          /** @param {Item?} n */
          (n) => {
            for (; n !== null; n = n.left) {
              n.parent = t;
            }
          }
        );
        t._start = type._start;
        for (let n = t._start; n !== null; n = n.right) {
          n.parent = t;
        }
        t._length = type._length;
        this.share.set(name, t);
        t._integrate(this, null);
        return (
          /** @type {InstanceType<Type>} */
          t
        );
      } else {
        throw new Error(`Type with the name ${name} has already been defined with a different constructor`);
      }
    }
    return (
      /** @type {InstanceType<Type>} */
      type
    );
  }
  /**
   * @template T
   * @param {string} [name]
   * @return {YArray<T>}
   *
   * @public
   */
  getArray(name = "") {
    return (
      /** @type {YArray<T>} */
      this.get(name, YArray)
    );
  }
  /**
   * @param {string} [name]
   * @return {YText}
   *
   * @public
   */
  getText(name = "") {
    return this.get(name, YText);
  }
  /**
   * @template T
   * @param {string} [name]
   * @return {YMap<T>}
   *
   * @public
   */
  getMap(name = "") {
    return (
      /** @type {YMap<T>} */
      this.get(name, YMap)
    );
  }
  /**
   * @param {string} [name]
   * @return {YXmlElement}
   *
   * @public
   */
  getXmlElement(name = "") {
    return (
      /** @type {YXmlElement<{[key:string]:string}>} */
      this.get(name, YXmlElement)
    );
  }
  /**
   * @param {string} [name]
   * @return {YXmlFragment}
   *
   * @public
   */
  getXmlFragment(name = "") {
    return this.get(name, YXmlFragment);
  }
  /**
   * Converts the entire document into a js object, recursively traversing each yjs type
   * Doesn't log types that have not been defined (using ydoc.getType(..)).
   *
   * @deprecated Do not use this method and rather call toJSON directly on the shared types.
   *
   * @return {Object<string, any>}
   */
  toJSON() {
    const doc = {};
    this.share.forEach((value, key2) => {
      doc[key2] = value.toJSON();
    });
    return doc;
  }
  /**
   * Emit `destroy` event and unregister all event handlers.
   */
  destroy() {
    this.isDestroyed = true;
    from(this.subdocs).forEach((subdoc) => subdoc.destroy());
    const item = this._item;
    if (item !== null) {
      this._item = null;
      const content = (
        /** @type {ContentDoc} */
        item.content
      );
      content.doc = new _Doc({ guid: this.guid, ...content.opts, shouldLoad: false });
      content.doc._item = item;
      transact(
        /** @type {any} */
        item.parent.doc,
        (transaction) => {
          const doc = content.doc;
          if (!item.deleted) {
            transaction.subdocsAdded.add(doc);
          }
          transaction.subdocsRemoved.add(this);
        },
        null,
        true
      );
    }
    this.emit("destroyed", [true]);
    this.emit("destroy", [this]);
    super.destroy();
  }
};
var DSDecoderV1 = class {
  /**
   * @param {decoding.Decoder} decoder
   */
  constructor(decoder) {
    this.restDecoder = decoder;
  }
  resetDsCurVal() {
  }
  /**
   * @return {number}
   */
  readDsClock() {
    return readVarUint(this.restDecoder);
  }
  /**
   * @return {number}
   */
  readDsLen() {
    return readVarUint(this.restDecoder);
  }
};
var UpdateDecoderV1 = class extends DSDecoderV1 {
  /**
   * @return {ID}
   */
  readLeftID() {
    return createID(readVarUint(this.restDecoder), readVarUint(this.restDecoder));
  }
  /**
   * @return {ID}
   */
  readRightID() {
    return createID(readVarUint(this.restDecoder), readVarUint(this.restDecoder));
  }
  /**
   * Read the next client id.
   * Use this in favor of readID whenever possible to reduce the number of objects created.
   */
  readClient() {
    return readVarUint(this.restDecoder);
  }
  /**
   * @return {number} info An unsigned 8-bit integer
   */
  readInfo() {
    return readUint8(this.restDecoder);
  }
  /**
   * @return {string}
   */
  readString() {
    return readVarString(this.restDecoder);
  }
  /**
   * @return {boolean} isKey
   */
  readParentInfo() {
    return readVarUint(this.restDecoder) === 1;
  }
  /**
   * @return {number} info An unsigned 8-bit integer
   */
  readTypeRef() {
    return readVarUint(this.restDecoder);
  }
  /**
   * Write len of a struct - well suited for Opt RLE encoder.
   *
   * @return {number} len
   */
  readLen() {
    return readVarUint(this.restDecoder);
  }
  /**
   * @return {any}
   */
  readAny() {
    return readAny(this.restDecoder);
  }
  /**
   * @return {Uint8Array}
   */
  readBuf() {
    return copyUint8Array(readVarUint8Array(this.restDecoder));
  }
  /**
   * Legacy implementation uses JSON parse. We use any-decoding in v2.
   *
   * @return {any}
   */
  readJSON() {
    return JSON.parse(readVarString(this.restDecoder));
  }
  /**
   * @return {string}
   */
  readKey() {
    return readVarString(this.restDecoder);
  }
};
var DSDecoderV2 = class {
  /**
   * @param {decoding.Decoder} decoder
   */
  constructor(decoder) {
    this.dsCurrVal = 0;
    this.restDecoder = decoder;
  }
  resetDsCurVal() {
    this.dsCurrVal = 0;
  }
  /**
   * @return {number}
   */
  readDsClock() {
    this.dsCurrVal += readVarUint(this.restDecoder);
    return this.dsCurrVal;
  }
  /**
   * @return {number}
   */
  readDsLen() {
    const diff = readVarUint(this.restDecoder) + 1;
    this.dsCurrVal += diff;
    return diff;
  }
};
var UpdateDecoderV2 = class extends DSDecoderV2 {
  /**
   * @param {decoding.Decoder} decoder
   */
  constructor(decoder) {
    super(decoder);
    this.keys = [];
    readVarUint(decoder);
    this.keyClockDecoder = new IntDiffOptRleDecoder(readVarUint8Array(decoder));
    this.clientDecoder = new UintOptRleDecoder(readVarUint8Array(decoder));
    this.leftClockDecoder = new IntDiffOptRleDecoder(readVarUint8Array(decoder));
    this.rightClockDecoder = new IntDiffOptRleDecoder(readVarUint8Array(decoder));
    this.infoDecoder = new RleDecoder(readVarUint8Array(decoder), readUint8);
    this.stringDecoder = new StringDecoder(readVarUint8Array(decoder));
    this.parentInfoDecoder = new RleDecoder(readVarUint8Array(decoder), readUint8);
    this.typeRefDecoder = new UintOptRleDecoder(readVarUint8Array(decoder));
    this.lenDecoder = new UintOptRleDecoder(readVarUint8Array(decoder));
  }
  /**
   * @return {ID}
   */
  readLeftID() {
    return new ID(this.clientDecoder.read(), this.leftClockDecoder.read());
  }
  /**
   * @return {ID}
   */
  readRightID() {
    return new ID(this.clientDecoder.read(), this.rightClockDecoder.read());
  }
  /**
   * Read the next client id.
   * Use this in favor of readID whenever possible to reduce the number of objects created.
   */
  readClient() {
    return this.clientDecoder.read();
  }
  /**
   * @return {number} info An unsigned 8-bit integer
   */
  readInfo() {
    return (
      /** @type {number} */
      this.infoDecoder.read()
    );
  }
  /**
   * @return {string}
   */
  readString() {
    return this.stringDecoder.read();
  }
  /**
   * @return {boolean}
   */
  readParentInfo() {
    return this.parentInfoDecoder.read() === 1;
  }
  /**
   * @return {number} An unsigned 8-bit integer
   */
  readTypeRef() {
    return this.typeRefDecoder.read();
  }
  /**
   * Write len of a struct - well suited for Opt RLE encoder.
   *
   * @return {number}
   */
  readLen() {
    return this.lenDecoder.read();
  }
  /**
   * @return {any}
   */
  readAny() {
    return readAny(this.restDecoder);
  }
  /**
   * @return {Uint8Array}
   */
  readBuf() {
    return readVarUint8Array(this.restDecoder);
  }
  /**
   * This is mainly here for legacy purposes.
   *
   * Initial we incoded objects using JSON. Now we use the much faster lib0/any-encoder. This method mainly exists for legacy purposes for the v1 encoder.
   *
   * @return {any}
   */
  readJSON() {
    return readAny(this.restDecoder);
  }
  /**
   * @return {string}
   */
  readKey() {
    const keyClock = this.keyClockDecoder.read();
    if (keyClock < this.keys.length) {
      return this.keys[keyClock];
    } else {
      const key2 = this.stringDecoder.read();
      this.keys.push(key2);
      return key2;
    }
  }
};
var DSEncoderV1 = class {
  constructor() {
    this.restEncoder = createEncoder();
  }
  toUint8Array() {
    return toUint8Array(this.restEncoder);
  }
  resetDsCurVal() {
  }
  /**
   * @param {number} clock
   */
  writeDsClock(clock) {
    writeVarUint(this.restEncoder, clock);
  }
  /**
   * @param {number} len
   */
  writeDsLen(len) {
    writeVarUint(this.restEncoder, len);
  }
};
var UpdateEncoderV1 = class extends DSEncoderV1 {
  /**
   * @param {ID} id
   */
  writeLeftID(id2) {
    writeVarUint(this.restEncoder, id2.client);
    writeVarUint(this.restEncoder, id2.clock);
  }
  /**
   * @param {ID} id
   */
  writeRightID(id2) {
    writeVarUint(this.restEncoder, id2.client);
    writeVarUint(this.restEncoder, id2.clock);
  }
  /**
   * Use writeClient and writeClock instead of writeID if possible.
   * @param {number} client
   */
  writeClient(client) {
    writeVarUint(this.restEncoder, client);
  }
  /**
   * @param {number} info An unsigned 8-bit integer
   */
  writeInfo(info) {
    writeUint8(this.restEncoder, info);
  }
  /**
   * @param {string} s
   */
  writeString(s) {
    writeVarString(this.restEncoder, s);
  }
  /**
   * @param {boolean} isYKey
   */
  writeParentInfo(isYKey) {
    writeVarUint(this.restEncoder, isYKey ? 1 : 0);
  }
  /**
   * @param {number} info An unsigned 8-bit integer
   */
  writeTypeRef(info) {
    writeVarUint(this.restEncoder, info);
  }
  /**
   * Write len of a struct - well suited for Opt RLE encoder.
   *
   * @param {number} len
   */
  writeLen(len) {
    writeVarUint(this.restEncoder, len);
  }
  /**
   * @param {any} any
   */
  writeAny(any2) {
    writeAny(this.restEncoder, any2);
  }
  /**
   * @param {Uint8Array} buf
   */
  writeBuf(buf) {
    writeVarUint8Array(this.restEncoder, buf);
  }
  /**
   * @param {any} embed
   */
  writeJSON(embed) {
    writeVarString(this.restEncoder, JSON.stringify(embed));
  }
  /**
   * @param {string} key
   */
  writeKey(key2) {
    writeVarString(this.restEncoder, key2);
  }
};
var DSEncoderV2 = class {
  constructor() {
    this.restEncoder = createEncoder();
    this.dsCurrVal = 0;
  }
  toUint8Array() {
    return toUint8Array(this.restEncoder);
  }
  resetDsCurVal() {
    this.dsCurrVal = 0;
  }
  /**
   * @param {number} clock
   */
  writeDsClock(clock) {
    const diff = clock - this.dsCurrVal;
    this.dsCurrVal = clock;
    writeVarUint(this.restEncoder, diff);
  }
  /**
   * @param {number} len
   */
  writeDsLen(len) {
    if (len === 0) {
      unexpectedCase();
    }
    writeVarUint(this.restEncoder, len - 1);
    this.dsCurrVal += len;
  }
};
var UpdateEncoderV2 = class extends DSEncoderV2 {
  constructor() {
    super();
    this.keyMap = /* @__PURE__ */ new Map();
    this.keyClock = 0;
    this.keyClockEncoder = new IntDiffOptRleEncoder();
    this.clientEncoder = new UintOptRleEncoder();
    this.leftClockEncoder = new IntDiffOptRleEncoder();
    this.rightClockEncoder = new IntDiffOptRleEncoder();
    this.infoEncoder = new RleEncoder(writeUint8);
    this.stringEncoder = new StringEncoder();
    this.parentInfoEncoder = new RleEncoder(writeUint8);
    this.typeRefEncoder = new UintOptRleEncoder();
    this.lenEncoder = new UintOptRleEncoder();
  }
  toUint8Array() {
    const encoder = createEncoder();
    writeVarUint(encoder, 0);
    writeVarUint8Array(encoder, this.keyClockEncoder.toUint8Array());
    writeVarUint8Array(encoder, this.clientEncoder.toUint8Array());
    writeVarUint8Array(encoder, this.leftClockEncoder.toUint8Array());
    writeVarUint8Array(encoder, this.rightClockEncoder.toUint8Array());
    writeVarUint8Array(encoder, toUint8Array(this.infoEncoder));
    writeVarUint8Array(encoder, this.stringEncoder.toUint8Array());
    writeVarUint8Array(encoder, toUint8Array(this.parentInfoEncoder));
    writeVarUint8Array(encoder, this.typeRefEncoder.toUint8Array());
    writeVarUint8Array(encoder, this.lenEncoder.toUint8Array());
    writeUint8Array(encoder, toUint8Array(this.restEncoder));
    return toUint8Array(encoder);
  }
  /**
   * @param {ID} id
   */
  writeLeftID(id2) {
    this.clientEncoder.write(id2.client);
    this.leftClockEncoder.write(id2.clock);
  }
  /**
   * @param {ID} id
   */
  writeRightID(id2) {
    this.clientEncoder.write(id2.client);
    this.rightClockEncoder.write(id2.clock);
  }
  /**
   * @param {number} client
   */
  writeClient(client) {
    this.clientEncoder.write(client);
  }
  /**
   * @param {number} info An unsigned 8-bit integer
   */
  writeInfo(info) {
    this.infoEncoder.write(info);
  }
  /**
   * @param {string} s
   */
  writeString(s) {
    this.stringEncoder.write(s);
  }
  /**
   * @param {boolean} isYKey
   */
  writeParentInfo(isYKey) {
    this.parentInfoEncoder.write(isYKey ? 1 : 0);
  }
  /**
   * @param {number} info An unsigned 8-bit integer
   */
  writeTypeRef(info) {
    this.typeRefEncoder.write(info);
  }
  /**
   * Write len of a struct - well suited for Opt RLE encoder.
   *
   * @param {number} len
   */
  writeLen(len) {
    this.lenEncoder.write(len);
  }
  /**
   * @param {any} any
   */
  writeAny(any2) {
    writeAny(this.restEncoder, any2);
  }
  /**
   * @param {Uint8Array} buf
   */
  writeBuf(buf) {
    writeVarUint8Array(this.restEncoder, buf);
  }
  /**
   * This is mainly here for legacy purposes.
   *
   * Initial we incoded objects using JSON. Now we use the much faster lib0/any-encoder. This method mainly exists for legacy purposes for the v1 encoder.
   *
   * @param {any} embed
   */
  writeJSON(embed) {
    writeAny(this.restEncoder, embed);
  }
  /**
   * Property keys are often reused. For example, in y-prosemirror the key `bold` might
   * occur very often. For a 3d application, the key `position` might occur very often.
   *
   * We cache these keys in a Map and refer to them via a unique number.
   *
   * @param {string} key
   */
  writeKey(key2) {
    const clock = this.keyMap.get(key2);
    if (clock === void 0) {
      this.keyClockEncoder.write(this.keyClock++);
      this.stringEncoder.write(key2);
    } else {
      this.keyClockEncoder.write(clock);
    }
  }
};
var writeStructs = (encoder, structs, client, clock) => {
  clock = max(clock, structs[0].id.clock);
  const startNewStructs = findIndexSS(structs, clock);
  writeVarUint(encoder.restEncoder, structs.length - startNewStructs);
  encoder.writeClient(client);
  writeVarUint(encoder.restEncoder, clock);
  const firstStruct = structs[startNewStructs];
  firstStruct.write(encoder, clock - firstStruct.id.clock);
  for (let i = startNewStructs + 1; i < structs.length; i++) {
    structs[i].write(encoder, 0);
  }
};
var writeClientsStructs = (encoder, store, _sm) => {
  const sm = /* @__PURE__ */ new Map();
  _sm.forEach((clock, client) => {
    if (getState(store, client) > clock) {
      sm.set(client, clock);
    }
  });
  getStateVector(store).forEach((_clock, client) => {
    if (!_sm.has(client)) {
      sm.set(client, 0);
    }
  });
  writeVarUint(encoder.restEncoder, sm.size);
  from(sm.entries()).sort((a, b) => b[0] - a[0]).forEach(([client, clock]) => {
    writeStructs(
      encoder,
      /** @type {Array<GC|Item>} */
      store.clients.get(client),
      client,
      clock
    );
  });
};
var readClientsStructRefs = (decoder, doc) => {
  const clientRefs = create();
  const numOfStateUpdates = readVarUint(decoder.restDecoder);
  for (let i = 0; i < numOfStateUpdates; i++) {
    const numberOfStructs = readVarUint(decoder.restDecoder);
    const refs = new Array(numberOfStructs);
    const client = decoder.readClient();
    let clock = readVarUint(decoder.restDecoder);
    clientRefs.set(client, { i: 0, refs });
    for (let i2 = 0; i2 < numberOfStructs; i2++) {
      const info = decoder.readInfo();
      switch (BITS5 & info) {
        case 0: {
          const len = decoder.readLen();
          refs[i2] = new GC(createID(client, clock), len);
          clock += len;
          break;
        }
        case 10: {
          const len = readVarUint(decoder.restDecoder);
          refs[i2] = new Skip(createID(client, clock), len);
          clock += len;
          break;
        }
        default: {
          const cantCopyParentInfo = (info & (BIT7 | BIT8)) === 0;
          const struct = new Item(
            createID(client, clock),
            null,
            // left
            (info & BIT8) === BIT8 ? decoder.readLeftID() : null,
            // origin
            null,
            // right
            (info & BIT7) === BIT7 ? decoder.readRightID() : null,
            // right origin
            cantCopyParentInfo ? decoder.readParentInfo() ? doc.get(decoder.readString()) : decoder.readLeftID() : null,
            // parent
            cantCopyParentInfo && (info & BIT6) === BIT6 ? decoder.readString() : null,
            // parentSub
            readItemContent(decoder, info)
            // item content
          );
          refs[i2] = struct;
          clock += struct.length;
        }
      }
    }
  }
  return clientRefs;
};
var integrateStructs = (transaction, store, clientsStructRefs) => {
  const stack = [];
  let clientsStructRefsIds = from(clientsStructRefs.keys()).sort((a, b) => a - b);
  if (clientsStructRefsIds.length === 0) {
    return null;
  }
  const getNextStructTarget = () => {
    if (clientsStructRefsIds.length === 0) {
      return null;
    }
    let nextStructsTarget = (
      /** @type {{i:number,refs:Array<GC|Item>}} */
      clientsStructRefs.get(clientsStructRefsIds[clientsStructRefsIds.length - 1])
    );
    while (nextStructsTarget.refs.length === nextStructsTarget.i) {
      clientsStructRefsIds.pop();
      if (clientsStructRefsIds.length > 0) {
        nextStructsTarget = /** @type {{i:number,refs:Array<GC|Item>}} */
        clientsStructRefs.get(clientsStructRefsIds[clientsStructRefsIds.length - 1]);
      } else {
        return null;
      }
    }
    return nextStructsTarget;
  };
  let curStructsTarget = getNextStructTarget();
  if (curStructsTarget === null) {
    return null;
  }
  const restStructs = new StructStore();
  const missingSV = /* @__PURE__ */ new Map();
  const updateMissingSv = (client, clock) => {
    const mclock = missingSV.get(client);
    if (mclock == null || mclock > clock) {
      missingSV.set(client, clock);
    }
  };
  let stackHead = (
    /** @type {any} */
    curStructsTarget.refs[
      /** @type {any} */
      curStructsTarget.i++
    ]
  );
  const state = /* @__PURE__ */ new Map();
  const addStackToRestSS = () => {
    for (const item of stack) {
      const client = item.id.client;
      const inapplicableItems = clientsStructRefs.get(client);
      if (inapplicableItems) {
        inapplicableItems.i--;
        restStructs.clients.set(client, inapplicableItems.refs.slice(inapplicableItems.i));
        clientsStructRefs.delete(client);
        inapplicableItems.i = 0;
        inapplicableItems.refs = [];
      } else {
        restStructs.clients.set(client, [item]);
      }
      clientsStructRefsIds = clientsStructRefsIds.filter((c) => c !== client);
    }
    stack.length = 0;
  };
  while (true) {
    if (stackHead.constructor !== Skip) {
      const localClock = setIfUndefined(state, stackHead.id.client, () => getState(store, stackHead.id.client));
      const offset = localClock - stackHead.id.clock;
      if (offset < 0) {
        stack.push(stackHead);
        updateMissingSv(stackHead.id.client, stackHead.id.clock - 1);
        addStackToRestSS();
      } else {
        const missing = stackHead.getMissing(transaction, store);
        if (missing !== null) {
          stack.push(stackHead);
          const structRefs = clientsStructRefs.get(
            /** @type {number} */
            missing
          ) || { refs: [], i: 0 };
          if (structRefs.refs.length === structRefs.i) {
            updateMissingSv(
              /** @type {number} */
              missing,
              getState(store, missing)
            );
            addStackToRestSS();
          } else {
            stackHead = structRefs.refs[structRefs.i++];
            continue;
          }
        } else if (offset === 0 || offset < stackHead.length) {
          stackHead.integrate(transaction, offset);
          state.set(stackHead.id.client, stackHead.id.clock + stackHead.length);
        }
      }
    }
    if (stack.length > 0) {
      stackHead = /** @type {GC|Item} */
      stack.pop();
    } else if (curStructsTarget !== null && curStructsTarget.i < curStructsTarget.refs.length) {
      stackHead = /** @type {GC|Item} */
      curStructsTarget.refs[curStructsTarget.i++];
    } else {
      curStructsTarget = getNextStructTarget();
      if (curStructsTarget === null) {
        break;
      } else {
        stackHead = /** @type {GC|Item} */
        curStructsTarget.refs[curStructsTarget.i++];
      }
    }
  }
  if (restStructs.clients.size > 0) {
    const encoder = new UpdateEncoderV2();
    writeClientsStructs(encoder, restStructs, /* @__PURE__ */ new Map());
    writeVarUint(encoder.restEncoder, 0);
    return { missing: missingSV, update: encoder.toUint8Array() };
  }
  return null;
};
var writeStructsFromTransaction = (encoder, transaction) => writeClientsStructs(encoder, transaction.doc.store, transaction.beforeState);
var readUpdateV2 = (decoder, ydoc, transactionOrigin, structDecoder = new UpdateDecoderV2(decoder)) => transact(ydoc, (transaction) => {
  transaction.local = false;
  let retry = false;
  const doc = transaction.doc;
  const store = doc.store;
  const ss = readClientsStructRefs(structDecoder, doc);
  const restStructs = integrateStructs(transaction, store, ss);
  const pending = store.pendingStructs;
  if (pending) {
    for (const [client, clock] of pending.missing) {
      if (clock < getState(store, client)) {
        retry = true;
        break;
      }
    }
    if (restStructs) {
      for (const [client, clock] of restStructs.missing) {
        const mclock = pending.missing.get(client);
        if (mclock == null || mclock > clock) {
          pending.missing.set(client, clock);
        }
      }
      pending.update = mergeUpdatesV2([pending.update, restStructs.update]);
    }
  } else {
    store.pendingStructs = restStructs;
  }
  const dsRest = readAndApplyDeleteSet(structDecoder, transaction, store);
  if (store.pendingDs) {
    const pendingDSUpdate = new UpdateDecoderV2(createDecoder(store.pendingDs));
    readVarUint(pendingDSUpdate.restDecoder);
    const dsRest2 = readAndApplyDeleteSet(pendingDSUpdate, transaction, store);
    if (dsRest && dsRest2) {
      store.pendingDs = mergeUpdatesV2([dsRest, dsRest2]);
    } else {
      store.pendingDs = dsRest || dsRest2;
    }
  } else {
    store.pendingDs = dsRest;
  }
  if (retry) {
    const update = (
      /** @type {{update: Uint8Array}} */
      store.pendingStructs.update
    );
    store.pendingStructs = null;
    applyUpdateV2(transaction.doc, update);
  }
}, transactionOrigin, false);
var applyUpdateV2 = (ydoc, update, transactionOrigin, YDecoder = UpdateDecoderV2) => {
  const decoder = createDecoder(update);
  readUpdateV2(decoder, ydoc, transactionOrigin, new YDecoder(decoder));
};
var applyUpdate = (ydoc, update, transactionOrigin) => applyUpdateV2(ydoc, update, transactionOrigin, UpdateDecoderV1);
var writeStateAsUpdate = (encoder, doc, targetStateVector = /* @__PURE__ */ new Map()) => {
  writeClientsStructs(encoder, doc.store, targetStateVector);
  writeDeleteSet(encoder, createDeleteSetFromStructStore(doc.store));
};
var encodeStateAsUpdateV2 = (doc, encodedTargetStateVector = new Uint8Array([0]), encoder = new UpdateEncoderV2()) => {
  const targetStateVector = decodeStateVector(encodedTargetStateVector);
  writeStateAsUpdate(encoder, doc, targetStateVector);
  const updates = [encoder.toUint8Array()];
  if (doc.store.pendingDs) {
    updates.push(doc.store.pendingDs);
  }
  if (doc.store.pendingStructs) {
    updates.push(diffUpdateV2(doc.store.pendingStructs.update, encodedTargetStateVector));
  }
  if (updates.length > 1) {
    if (encoder.constructor === UpdateEncoderV1) {
      return mergeUpdates(updates.map((update, i) => i === 0 ? update : convertUpdateFormatV2ToV1(update)));
    } else if (encoder.constructor === UpdateEncoderV2) {
      return mergeUpdatesV2(updates);
    }
  }
  return updates[0];
};
var encodeStateAsUpdate = (doc, encodedTargetStateVector) => encodeStateAsUpdateV2(doc, encodedTargetStateVector, new UpdateEncoderV1());
var readStateVector = (decoder) => {
  const ss = /* @__PURE__ */ new Map();
  const ssLength = readVarUint(decoder.restDecoder);
  for (let i = 0; i < ssLength; i++) {
    const client = readVarUint(decoder.restDecoder);
    const clock = readVarUint(decoder.restDecoder);
    ss.set(client, clock);
  }
  return ss;
};
var decodeStateVector = (decodedState) => readStateVector(new DSDecoderV1(createDecoder(decodedState)));
var writeStateVector = (encoder, sv) => {
  writeVarUint(encoder.restEncoder, sv.size);
  from(sv.entries()).sort((a, b) => b[0] - a[0]).forEach(([client, clock]) => {
    writeVarUint(encoder.restEncoder, client);
    writeVarUint(encoder.restEncoder, clock);
  });
  return encoder;
};
var writeDocumentStateVector = (encoder, doc) => writeStateVector(encoder, getStateVector(doc.store));
var encodeStateVectorV2 = (doc, encoder = new DSEncoderV2()) => {
  if (doc instanceof Map) {
    writeStateVector(encoder, doc);
  } else {
    writeDocumentStateVector(encoder, doc);
  }
  return encoder.toUint8Array();
};
var encodeStateVector = (doc) => encodeStateVectorV2(doc, new DSEncoderV1());
var EventHandler = class {
  constructor() {
    this.l = [];
  }
};
var createEventHandler = () => new EventHandler();
var addEventHandlerListener = (eventHandler, f) => eventHandler.l.push(f);
var removeEventHandlerListener = (eventHandler, f) => {
  const l = eventHandler.l;
  const len = l.length;
  eventHandler.l = l.filter((g) => f !== g);
  if (len === eventHandler.l.length) {
    console.error("[yjs] Tried to remove event handler that doesn't exist.");
  }
};
var callEventHandlerListeners = (eventHandler, arg0, arg1) => callAll(eventHandler.l, [arg0, arg1]);
var ID = class {
  /**
   * @param {number} client client id
   * @param {number} clock unique per client id, continuous number
   */
  constructor(client, clock) {
    this.client = client;
    this.clock = clock;
  }
};
var compareIDs = (a, b) => a === b || a !== null && b !== null && a.client === b.client && a.clock === b.clock;
var createID = (client, clock) => new ID(client, clock);
var findRootTypeKey = (type) => {
  for (const [key2, value] of type.doc.share.entries()) {
    if (value === type) {
      return key2;
    }
  }
  throw unexpectedCase();
};
var RelativePosition = class {
  /**
   * @param {ID|null} type
   * @param {string|null} tname
   * @param {ID|null} item
   * @param {number} assoc
   */
  constructor(type, tname, item, assoc = 0) {
    this.type = type;
    this.tname = tname;
    this.item = item;
    this.assoc = assoc;
  }
};
var relativePositionToJSON = (rpos) => {
  const json = {};
  if (rpos.type) {
    json.type = rpos.type;
  }
  if (rpos.tname) {
    json.tname = rpos.tname;
  }
  if (rpos.item) {
    json.item = rpos.item;
  }
  if (rpos.assoc != null) {
    json.assoc = rpos.assoc;
  }
  return json;
};
var AbsolutePosition = class {
  /**
   * @param {AbstractType<any>} type
   * @param {number} index
   * @param {number} [assoc]
   */
  constructor(type, index, assoc = 0) {
    this.type = type;
    this.index = index;
    this.assoc = assoc;
  }
};
var createAbsolutePosition = (type, index, assoc = 0) => new AbsolutePosition(type, index, assoc);
var createRelativePosition = (type, item, assoc) => {
  let typeid = null;
  let tname = null;
  if (type._item === null) {
    tname = findRootTypeKey(type);
  } else {
    typeid = createID(type._item.id.client, type._item.id.clock);
  }
  return new RelativePosition(typeid, tname, item, assoc);
};
var createRelativePositionFromTypeIndex = (type, index, assoc = 0) => {
  let t = type._start;
  if (assoc < 0) {
    if (index === 0) {
      return createRelativePosition(type, null, assoc);
    }
    index--;
  }
  while (t !== null) {
    if (!t.deleted && t.countable) {
      if (t.length > index) {
        return createRelativePosition(type, createID(t.id.client, t.id.clock + index), assoc);
      }
      index -= t.length;
    }
    if (t.right === null && assoc < 0) {
      return createRelativePosition(type, t.lastId, assoc);
    }
    t = t.right;
  }
  return createRelativePosition(type, null, assoc);
};
var getItemWithOffset = (store, id2) => {
  const item = getItem(store, id2);
  const diff = id2.clock - item.id.clock;
  return {
    item,
    diff
  };
};
var createAbsolutePositionFromRelativePosition = (rpos, doc, followUndoneDeletions = true) => {
  const store = doc.store;
  const rightID = rpos.item;
  const typeID = rpos.type;
  const tname = rpos.tname;
  const assoc = rpos.assoc;
  let type = null;
  let index = 0;
  if (rightID !== null) {
    if (getState(store, rightID.client) <= rightID.clock) {
      return null;
    }
    const res = followUndoneDeletions ? followRedone(store, rightID) : getItemWithOffset(store, rightID);
    const right = res.item;
    if (!(right instanceof Item)) {
      return null;
    }
    type = /** @type {AbstractType<any>} */
    right.parent;
    if (type._item === null || !type._item.deleted) {
      index = right.deleted || !right.countable ? 0 : res.diff + (assoc >= 0 ? 0 : 1);
      let n = right.left;
      while (n !== null) {
        if (!n.deleted && n.countable) {
          index += n.length;
        }
        n = n.left;
      }
    }
  } else {
    if (tname !== null) {
      type = doc.get(tname);
    } else if (typeID !== null) {
      if (getState(store, typeID.client) <= typeID.clock) {
        return null;
      }
      const { item } = followUndoneDeletions ? followRedone(store, typeID) : { item: getItem(store, typeID) };
      if (item instanceof Item && item.content instanceof ContentType) {
        type = item.content.type;
      } else {
        return null;
      }
    } else {
      throw unexpectedCase();
    }
    if (assoc >= 0) {
      index = type._length;
    } else {
      index = 0;
    }
  }
  return createAbsolutePosition(type, index, rpos.assoc);
};
var Snapshot = class {
  /**
   * @param {DeleteSet} ds
   * @param {Map<number,number>} sv state map
   */
  constructor(ds, sv) {
    this.ds = ds;
    this.sv = sv;
  }
};
var createSnapshot = (ds, sm) => new Snapshot(ds, sm);
var emptySnapshot = createSnapshot(createDeleteSet(), /* @__PURE__ */ new Map());
var isVisible = (item, snapshot) => snapshot === void 0 ? !item.deleted : snapshot.sv.has(item.id.client) && (snapshot.sv.get(item.id.client) || 0) > item.id.clock && !isDeleted(snapshot.ds, item.id);
var splitSnapshotAffectedStructs = (transaction, snapshot) => {
  const meta = setIfUndefined(transaction.meta, splitSnapshotAffectedStructs, create2);
  const store = transaction.doc.store;
  if (!meta.has(snapshot)) {
    snapshot.sv.forEach((clock, client) => {
      if (clock < getState(store, client)) {
        getItemCleanStart(transaction, createID(client, clock));
      }
    });
    iterateDeletedStructs(transaction, snapshot.ds, (_item) => {
    });
    meta.add(snapshot);
  }
};
var StructStore = class {
  constructor() {
    this.clients = /* @__PURE__ */ new Map();
    this.pendingStructs = null;
    this.pendingDs = null;
  }
};
var getStateVector = (store) => {
  const sm = /* @__PURE__ */ new Map();
  store.clients.forEach((structs, client) => {
    const struct = structs[structs.length - 1];
    sm.set(client, struct.id.clock + struct.length);
  });
  return sm;
};
var getState = (store, client) => {
  const structs = store.clients.get(client);
  if (structs === void 0) {
    return 0;
  }
  const lastStruct = structs[structs.length - 1];
  return lastStruct.id.clock + lastStruct.length;
};
var addStruct = (store, struct) => {
  let structs = store.clients.get(struct.id.client);
  if (structs === void 0) {
    structs = [];
    store.clients.set(struct.id.client, structs);
  } else {
    const lastStruct = structs[structs.length - 1];
    if (lastStruct.id.clock + lastStruct.length !== struct.id.clock) {
      throw unexpectedCase();
    }
  }
  structs.push(struct);
};
var findIndexSS = (structs, clock) => {
  let left = 0;
  let right = structs.length - 1;
  let mid = structs[right];
  let midclock = mid.id.clock;
  if (midclock === clock) {
    return right;
  }
  let midindex = floor(clock / (midclock + mid.length - 1) * right);
  while (left <= right) {
    mid = structs[midindex];
    midclock = mid.id.clock;
    if (midclock <= clock) {
      if (clock < midclock + mid.length) {
        return midindex;
      }
      left = midindex + 1;
    } else {
      right = midindex - 1;
    }
    midindex = floor((left + right) / 2);
  }
  throw unexpectedCase();
};
var find = (store, id2) => {
  const structs = store.clients.get(id2.client);
  return structs[findIndexSS(structs, id2.clock)];
};
var getItem = (
  /** @type {function(StructStore,ID):Item} */
  find
);
var findIndexCleanStart = (transaction, structs, clock) => {
  const index = findIndexSS(structs, clock);
  const struct = structs[index];
  if (struct.id.clock < clock && struct instanceof Item) {
    structs.splice(index + 1, 0, splitItem(transaction, struct, clock - struct.id.clock));
    return index + 1;
  }
  return index;
};
var getItemCleanStart = (transaction, id2) => {
  const structs = (
    /** @type {Array<Item>} */
    transaction.doc.store.clients.get(id2.client)
  );
  return structs[findIndexCleanStart(transaction, structs, id2.clock)];
};
var getItemCleanEnd = (transaction, store, id2) => {
  const structs = store.clients.get(id2.client);
  const index = findIndexSS(structs, id2.clock);
  const struct = structs[index];
  if (id2.clock !== struct.id.clock + struct.length - 1 && struct.constructor !== GC) {
    structs.splice(index + 1, 0, splitItem(transaction, struct, id2.clock - struct.id.clock + 1));
  }
  return struct;
};
var replaceStruct = (store, struct, newStruct) => {
  const structs = (
    /** @type {Array<GC|Item>} */
    store.clients.get(struct.id.client)
  );
  structs[findIndexSS(structs, struct.id.clock)] = newStruct;
};
var iterateStructs = (transaction, structs, clockStart, len, f) => {
  if (len === 0) {
    return;
  }
  const clockEnd = clockStart + len;
  let index = findIndexCleanStart(transaction, structs, clockStart);
  let struct;
  do {
    struct = structs[index++];
    if (clockEnd < struct.id.clock + struct.length) {
      findIndexCleanStart(transaction, structs, clockEnd);
    }
    f(struct);
  } while (index < structs.length && structs[index].id.clock < clockEnd);
};
var Transaction = class {
  /**
   * @param {Doc} doc
   * @param {any} origin
   * @param {boolean} local
   */
  constructor(doc, origin, local) {
    this.doc = doc;
    this.deleteSet = new DeleteSet();
    this.beforeState = getStateVector(doc.store);
    this.afterState = /* @__PURE__ */ new Map();
    this.changed = /* @__PURE__ */ new Map();
    this.changedParentTypes = /* @__PURE__ */ new Map();
    this._mergeStructs = [];
    this.origin = origin;
    this.meta = /* @__PURE__ */ new Map();
    this.local = local;
    this.subdocsAdded = /* @__PURE__ */ new Set();
    this.subdocsRemoved = /* @__PURE__ */ new Set();
    this.subdocsLoaded = /* @__PURE__ */ new Set();
    this._needFormattingCleanup = false;
  }
};
var writeUpdateMessageFromTransaction = (encoder, transaction) => {
  if (transaction.deleteSet.clients.size === 0 && !any(transaction.afterState, (clock, client) => transaction.beforeState.get(client) !== clock)) {
    return false;
  }
  sortAndMergeDeleteSet(transaction.deleteSet);
  writeStructsFromTransaction(encoder, transaction);
  writeDeleteSet(encoder, transaction.deleteSet);
  return true;
};
var addChangedTypeToTransaction = (transaction, type, parentSub) => {
  const item = type._item;
  if (item === null || item.id.clock < (transaction.beforeState.get(item.id.client) || 0) && !item.deleted) {
    setIfUndefined(transaction.changed, type, create2).add(parentSub);
  }
};
var tryToMergeWithLefts = (structs, pos) => {
  let right = structs[pos];
  let left = structs[pos - 1];
  let i = pos;
  for (; i > 0; right = left, left = structs[--i - 1]) {
    if (left.deleted === right.deleted && left.constructor === right.constructor) {
      if (left.mergeWith(right)) {
        if (right instanceof Item && right.parentSub !== null && /** @type {AbstractType<any>} */
        right.parent._map.get(right.parentSub) === right) {
          right.parent._map.set(
            right.parentSub,
            /** @type {Item} */
            left
          );
        }
        continue;
      }
    }
    break;
  }
  const merged = pos - i;
  if (merged) {
    structs.splice(pos + 1 - merged, merged);
  }
  return merged;
};
var tryGcDeleteSet = (ds, store, gcFilter) => {
  for (const [client, deleteItems] of ds.clients.entries()) {
    const structs = (
      /** @type {Array<GC|Item>} */
      store.clients.get(client)
    );
    for (let di = deleteItems.length - 1; di >= 0; di--) {
      const deleteItem = deleteItems[di];
      const endDeleteItemClock = deleteItem.clock + deleteItem.len;
      for (let si = findIndexSS(structs, deleteItem.clock), struct = structs[si]; si < structs.length && struct.id.clock < endDeleteItemClock; struct = structs[++si]) {
        const struct2 = structs[si];
        if (deleteItem.clock + deleteItem.len <= struct2.id.clock) {
          break;
        }
        if (struct2 instanceof Item && struct2.deleted && !struct2.keep && gcFilter(struct2)) {
          struct2.gc(store, false);
        }
      }
    }
  }
};
var tryMergeDeleteSet = (ds, store) => {
  ds.clients.forEach((deleteItems, client) => {
    const structs = (
      /** @type {Array<GC|Item>} */
      store.clients.get(client)
    );
    for (let di = deleteItems.length - 1; di >= 0; di--) {
      const deleteItem = deleteItems[di];
      const mostRightIndexToCheck = min(structs.length - 1, 1 + findIndexSS(structs, deleteItem.clock + deleteItem.len - 1));
      for (let si = mostRightIndexToCheck, struct = structs[si]; si > 0 && struct.id.clock >= deleteItem.clock; struct = structs[si]) {
        si -= 1 + tryToMergeWithLefts(structs, si);
      }
    }
  });
};
var cleanupTransactions = (transactionCleanups, i) => {
  if (i < transactionCleanups.length) {
    const transaction = transactionCleanups[i];
    const doc = transaction.doc;
    const store = doc.store;
    const ds = transaction.deleteSet;
    const mergeStructs = transaction._mergeStructs;
    try {
      sortAndMergeDeleteSet(ds);
      transaction.afterState = getStateVector(transaction.doc.store);
      doc.emit("beforeObserverCalls", [transaction, doc]);
      const fs = [];
      transaction.changed.forEach(
        (subs, itemtype) => fs.push(() => {
          if (itemtype._item === null || !itemtype._item.deleted) {
            itemtype._callObserver(transaction, subs);
          }
        })
      );
      fs.push(() => {
        transaction.changedParentTypes.forEach((events, type) => {
          if (type._dEH.l.length > 0 && (type._item === null || !type._item.deleted)) {
            events = events.filter(
              (event) => event.target._item === null || !event.target._item.deleted
            );
            events.forEach((event) => {
              event.currentTarget = type;
              event._path = null;
            });
            events.sort((event1, event2) => event1.path.length - event2.path.length);
            fs.push(() => {
              callEventHandlerListeners(type._dEH, events, transaction);
            });
          }
        });
        fs.push(() => doc.emit("afterTransaction", [transaction, doc]));
        fs.push(() => {
          if (transaction._needFormattingCleanup) {
            cleanupYTextAfterTransaction(transaction);
          }
        });
      });
      callAll(fs, []);
    } finally {
      if (doc.gc) {
        tryGcDeleteSet(ds, store, doc.gcFilter);
      }
      tryMergeDeleteSet(ds, store);
      transaction.afterState.forEach((clock, client) => {
        const beforeClock = transaction.beforeState.get(client) || 0;
        if (beforeClock !== clock) {
          const structs = (
            /** @type {Array<GC|Item>} */
            store.clients.get(client)
          );
          const firstChangePos = max(findIndexSS(structs, beforeClock), 1);
          for (let i2 = structs.length - 1; i2 >= firstChangePos; ) {
            i2 -= 1 + tryToMergeWithLefts(structs, i2);
          }
        }
      });
      for (let i2 = mergeStructs.length - 1; i2 >= 0; i2--) {
        const { client, clock } = mergeStructs[i2].id;
        const structs = (
          /** @type {Array<GC|Item>} */
          store.clients.get(client)
        );
        const replacedStructPos = findIndexSS(structs, clock);
        if (replacedStructPos + 1 < structs.length) {
          if (tryToMergeWithLefts(structs, replacedStructPos + 1) > 1) {
            continue;
          }
        }
        if (replacedStructPos > 0) {
          tryToMergeWithLefts(structs, replacedStructPos);
        }
      }
      if (!transaction.local && transaction.afterState.get(doc.clientID) !== transaction.beforeState.get(doc.clientID)) {
        print(ORANGE, BOLD, "[yjs] ", UNBOLD, RED, "Changed the client-id because another client seems to be using it.");
        doc.clientID = generateNewClientId();
      }
      doc.emit("afterTransactionCleanup", [transaction, doc]);
      if (doc._observers.has("update")) {
        const encoder = new UpdateEncoderV1();
        const hasContent2 = writeUpdateMessageFromTransaction(encoder, transaction);
        if (hasContent2) {
          doc.emit("update", [encoder.toUint8Array(), transaction.origin, doc, transaction]);
        }
      }
      if (doc._observers.has("updateV2")) {
        const encoder = new UpdateEncoderV2();
        const hasContent2 = writeUpdateMessageFromTransaction(encoder, transaction);
        if (hasContent2) {
          doc.emit("updateV2", [encoder.toUint8Array(), transaction.origin, doc, transaction]);
        }
      }
      const { subdocsAdded, subdocsLoaded, subdocsRemoved } = transaction;
      if (subdocsAdded.size > 0 || subdocsRemoved.size > 0 || subdocsLoaded.size > 0) {
        subdocsAdded.forEach((subdoc) => {
          subdoc.clientID = doc.clientID;
          if (subdoc.collectionid == null) {
            subdoc.collectionid = doc.collectionid;
          }
          doc.subdocs.add(subdoc);
        });
        subdocsRemoved.forEach((subdoc) => doc.subdocs.delete(subdoc));
        doc.emit("subdocs", [{ loaded: subdocsLoaded, added: subdocsAdded, removed: subdocsRemoved }, doc, transaction]);
        subdocsRemoved.forEach((subdoc) => subdoc.destroy());
      }
      if (transactionCleanups.length <= i + 1) {
        doc._transactionCleanups = [];
        doc.emit("afterAllTransactions", [doc, transactionCleanups]);
      } else {
        cleanupTransactions(transactionCleanups, i + 1);
      }
    }
  }
};
var transact = (doc, f, origin = null, local = true) => {
  const transactionCleanups = doc._transactionCleanups;
  let initialCall = false;
  let result = null;
  if (doc._transaction === null) {
    initialCall = true;
    doc._transaction = new Transaction(doc, origin, local);
    transactionCleanups.push(doc._transaction);
    if (transactionCleanups.length === 1) {
      doc.emit("beforeAllTransactions", [doc]);
    }
    doc.emit("beforeTransaction", [doc._transaction, doc]);
  }
  try {
    result = f(doc._transaction);
  } finally {
    if (initialCall) {
      const finishCleanup = doc._transaction === transactionCleanups[0];
      doc._transaction = null;
      if (finishCleanup) {
        cleanupTransactions(transactionCleanups, 0);
      }
    }
  }
  return result;
};
function* lazyStructReaderGenerator(decoder) {
  const numOfStateUpdates = readVarUint(decoder.restDecoder);
  for (let i = 0; i < numOfStateUpdates; i++) {
    const numberOfStructs = readVarUint(decoder.restDecoder);
    const client = decoder.readClient();
    let clock = readVarUint(decoder.restDecoder);
    for (let i2 = 0; i2 < numberOfStructs; i2++) {
      const info = decoder.readInfo();
      if (info === 10) {
        const len = readVarUint(decoder.restDecoder);
        yield new Skip(createID(client, clock), len);
        clock += len;
      } else if ((BITS5 & info) !== 0) {
        const cantCopyParentInfo = (info & (BIT7 | BIT8)) === 0;
        const struct = new Item(
          createID(client, clock),
          null,
          // left
          (info & BIT8) === BIT8 ? decoder.readLeftID() : null,
          // origin
          null,
          // right
          (info & BIT7) === BIT7 ? decoder.readRightID() : null,
          // right origin
          // @ts-ignore Force writing a string here.
          cantCopyParentInfo ? decoder.readParentInfo() ? decoder.readString() : decoder.readLeftID() : null,
          // parent
          cantCopyParentInfo && (info & BIT6) === BIT6 ? decoder.readString() : null,
          // parentSub
          readItemContent(decoder, info)
          // item content
        );
        yield struct;
        clock += struct.length;
      } else {
        const len = decoder.readLen();
        yield new GC(createID(client, clock), len);
        clock += len;
      }
    }
  }
}
var LazyStructReader = class {
  /**
   * @param {UpdateDecoderV1 | UpdateDecoderV2} decoder
   * @param {boolean} filterSkips
   */
  constructor(decoder, filterSkips) {
    this.gen = lazyStructReaderGenerator(decoder);
    this.curr = null;
    this.done = false;
    this.filterSkips = filterSkips;
    this.next();
  }
  /**
   * @return {Item | GC | Skip |null}
   */
  next() {
    do {
      this.curr = this.gen.next().value || null;
    } while (this.filterSkips && this.curr !== null && this.curr.constructor === Skip);
    return this.curr;
  }
};
var decodeUpdate = (update) => decodeUpdateV2(update, UpdateDecoderV1);
var decodeUpdateV2 = (update, YDecoder = UpdateDecoderV2) => {
  const structs = [];
  const updateDecoder = new YDecoder(createDecoder(update));
  const lazyDecoder = new LazyStructReader(updateDecoder, false);
  for (let curr = lazyDecoder.curr; curr !== null; curr = lazyDecoder.next()) {
    structs.push(curr);
  }
  return {
    structs,
    ds: readDeleteSet(updateDecoder)
  };
};
var LazyStructWriter = class {
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   */
  constructor(encoder) {
    this.currClient = 0;
    this.startClock = 0;
    this.written = 0;
    this.encoder = encoder;
    this.clientStructs = [];
  }
};
var mergeUpdates = (updates) => mergeUpdatesV2(updates, UpdateDecoderV1, UpdateEncoderV1);
var sliceStruct = (left, diff) => {
  if (left.constructor === GC) {
    const { client, clock } = left.id;
    return new GC(createID(client, clock + diff), left.length - diff);
  } else if (left.constructor === Skip) {
    const { client, clock } = left.id;
    return new Skip(createID(client, clock + diff), left.length - diff);
  } else {
    const leftItem = (
      /** @type {Item} */
      left
    );
    const { client, clock } = leftItem.id;
    return new Item(
      createID(client, clock + diff),
      null,
      createID(client, clock + diff - 1),
      null,
      leftItem.rightOrigin,
      leftItem.parent,
      leftItem.parentSub,
      leftItem.content.splice(diff)
    );
  }
};
var mergeUpdatesV2 = (updates, YDecoder = UpdateDecoderV2, YEncoder = UpdateEncoderV2) => {
  if (updates.length === 1) {
    return updates[0];
  }
  const updateDecoders = updates.map((update) => new YDecoder(createDecoder(update)));
  let lazyStructDecoders = updateDecoders.map((decoder) => new LazyStructReader(decoder, true));
  let currWrite = null;
  const updateEncoder = new YEncoder();
  const lazyStructEncoder = new LazyStructWriter(updateEncoder);
  while (true) {
    lazyStructDecoders = lazyStructDecoders.filter((dec2) => dec2.curr !== null);
    lazyStructDecoders.sort(
      /** @type {function(any,any):number} */
      (dec1, dec2) => {
        if (dec1.curr.id.client === dec2.curr.id.client) {
          const clockDiff = dec1.curr.id.clock - dec2.curr.id.clock;
          if (clockDiff === 0) {
            return dec1.curr.constructor === dec2.curr.constructor ? 0 : dec1.curr.constructor === Skip ? 1 : -1;
          } else {
            return clockDiff;
          }
        } else {
          return dec2.curr.id.client - dec1.curr.id.client;
        }
      }
    );
    if (lazyStructDecoders.length === 0) {
      break;
    }
    const currDecoder = lazyStructDecoders[0];
    const firstClient = (
      /** @type {Item | GC} */
      currDecoder.curr.id.client
    );
    if (currWrite !== null) {
      let curr = (
        /** @type {Item | GC | null} */
        currDecoder.curr
      );
      let iterated = false;
      while (curr !== null && curr.id.clock + curr.length <= currWrite.struct.id.clock + currWrite.struct.length && curr.id.client >= currWrite.struct.id.client) {
        curr = currDecoder.next();
        iterated = true;
      }
      if (curr === null || // current decoder is empty
      curr.id.client !== firstClient || // check whether there is another decoder that has has updates from `firstClient`
      iterated && curr.id.clock > currWrite.struct.id.clock + currWrite.struct.length) {
        continue;
      }
      if (firstClient !== currWrite.struct.id.client) {
        writeStructToLazyStructWriter(lazyStructEncoder, currWrite.struct, currWrite.offset);
        currWrite = { struct: curr, offset: 0 };
        currDecoder.next();
      } else {
        if (currWrite.struct.id.clock + currWrite.struct.length < curr.id.clock) {
          if (currWrite.struct.constructor === Skip) {
            currWrite.struct.length = curr.id.clock + curr.length - currWrite.struct.id.clock;
          } else {
            writeStructToLazyStructWriter(lazyStructEncoder, currWrite.struct, currWrite.offset);
            const diff = curr.id.clock - currWrite.struct.id.clock - currWrite.struct.length;
            const struct = new Skip(createID(firstClient, currWrite.struct.id.clock + currWrite.struct.length), diff);
            currWrite = { struct, offset: 0 };
          }
        } else {
          const diff = currWrite.struct.id.clock + currWrite.struct.length - curr.id.clock;
          if (diff > 0) {
            if (currWrite.struct.constructor === Skip) {
              currWrite.struct.length -= diff;
            } else {
              curr = sliceStruct(curr, diff);
            }
          }
          if (!currWrite.struct.mergeWith(
            /** @type {any} */
            curr
          )) {
            writeStructToLazyStructWriter(lazyStructEncoder, currWrite.struct, currWrite.offset);
            currWrite = { struct: curr, offset: 0 };
            currDecoder.next();
          }
        }
      }
    } else {
      currWrite = { struct: (
        /** @type {Item | GC} */
        currDecoder.curr
      ), offset: 0 };
      currDecoder.next();
    }
    for (let next = currDecoder.curr; next !== null && next.id.client === firstClient && next.id.clock === currWrite.struct.id.clock + currWrite.struct.length && next.constructor !== Skip; next = currDecoder.next()) {
      writeStructToLazyStructWriter(lazyStructEncoder, currWrite.struct, currWrite.offset);
      currWrite = { struct: next, offset: 0 };
    }
  }
  if (currWrite !== null) {
    writeStructToLazyStructWriter(lazyStructEncoder, currWrite.struct, currWrite.offset);
    currWrite = null;
  }
  finishLazyStructWriting(lazyStructEncoder);
  const dss = updateDecoders.map((decoder) => readDeleteSet(decoder));
  const ds = mergeDeleteSets(dss);
  writeDeleteSet(updateEncoder, ds);
  return updateEncoder.toUint8Array();
};
var diffUpdateV2 = (update, sv, YDecoder = UpdateDecoderV2, YEncoder = UpdateEncoderV2) => {
  const state = decodeStateVector(sv);
  const encoder = new YEncoder();
  const lazyStructWriter = new LazyStructWriter(encoder);
  const decoder = new YDecoder(createDecoder(update));
  const reader = new LazyStructReader(decoder, false);
  while (reader.curr) {
    const curr = reader.curr;
    const currClient = curr.id.client;
    const svClock = state.get(currClient) || 0;
    if (reader.curr.constructor === Skip) {
      reader.next();
      continue;
    }
    if (curr.id.clock + curr.length > svClock) {
      writeStructToLazyStructWriter(lazyStructWriter, curr, max(svClock - curr.id.clock, 0));
      reader.next();
      while (reader.curr && reader.curr.id.client === currClient) {
        writeStructToLazyStructWriter(lazyStructWriter, reader.curr, 0);
        reader.next();
      }
    } else {
      while (reader.curr && reader.curr.id.client === currClient && reader.curr.id.clock + reader.curr.length <= svClock) {
        reader.next();
      }
    }
  }
  finishLazyStructWriting(lazyStructWriter);
  const ds = readDeleteSet(decoder);
  writeDeleteSet(encoder, ds);
  return encoder.toUint8Array();
};
var flushLazyStructWriter = (lazyWriter) => {
  if (lazyWriter.written > 0) {
    lazyWriter.clientStructs.push({ written: lazyWriter.written, restEncoder: toUint8Array(lazyWriter.encoder.restEncoder) });
    lazyWriter.encoder.restEncoder = createEncoder();
    lazyWriter.written = 0;
  }
};
var writeStructToLazyStructWriter = (lazyWriter, struct, offset) => {
  if (lazyWriter.written > 0 && lazyWriter.currClient !== struct.id.client) {
    flushLazyStructWriter(lazyWriter);
  }
  if (lazyWriter.written === 0) {
    lazyWriter.currClient = struct.id.client;
    lazyWriter.encoder.writeClient(struct.id.client);
    writeVarUint(lazyWriter.encoder.restEncoder, struct.id.clock + offset);
  }
  struct.write(lazyWriter.encoder, offset);
  lazyWriter.written++;
};
var finishLazyStructWriting = (lazyWriter) => {
  flushLazyStructWriter(lazyWriter);
  const restEncoder = lazyWriter.encoder.restEncoder;
  writeVarUint(restEncoder, lazyWriter.clientStructs.length);
  for (let i = 0; i < lazyWriter.clientStructs.length; i++) {
    const partStructs = lazyWriter.clientStructs[i];
    writeVarUint(restEncoder, partStructs.written);
    writeUint8Array(restEncoder, partStructs.restEncoder);
  }
};
var convertUpdateFormat = (update, blockTransformer, YDecoder, YEncoder) => {
  const updateDecoder = new YDecoder(createDecoder(update));
  const lazyDecoder = new LazyStructReader(updateDecoder, false);
  const updateEncoder = new YEncoder();
  const lazyWriter = new LazyStructWriter(updateEncoder);
  for (let curr = lazyDecoder.curr; curr !== null; curr = lazyDecoder.next()) {
    writeStructToLazyStructWriter(lazyWriter, blockTransformer(curr), 0);
  }
  finishLazyStructWriting(lazyWriter);
  const ds = readDeleteSet(updateDecoder);
  writeDeleteSet(updateEncoder, ds);
  return updateEncoder.toUint8Array();
};
var convertUpdateFormatV2ToV1 = (update) => convertUpdateFormat(update, id, UpdateDecoderV2, UpdateEncoderV1);
var errorComputeChanges = "You must not compute changes after the event-handler fired.";
var YEvent = class {
  /**
   * @param {T} target The changed type.
   * @param {Transaction} transaction
   */
  constructor(target, transaction) {
    this.target = target;
    this.currentTarget = target;
    this.transaction = transaction;
    this._changes = null;
    this._keys = null;
    this._delta = null;
    this._path = null;
  }
  /**
   * Computes the path from `y` to the changed type.
   *
   * @todo v14 should standardize on path: Array<{parent, index}> because that is easier to work with.
   *
   * The following property holds:
   * @example
   *   let type = y
   *   event.path.forEach(dir => {
   *     type = type.get(dir)
   *   })
   *   type === event.target // => true
   */
  get path() {
    return this._path || (this._path = getPathTo(this.currentTarget, this.target));
  }
  /**
   * Check if a struct is deleted by this event.
   *
   * In contrast to change.deleted, this method also returns true if the struct was added and then deleted.
   *
   * @param {AbstractStruct} struct
   * @return {boolean}
   */
  deletes(struct) {
    return isDeleted(this.transaction.deleteSet, struct.id);
  }
  /**
   * @type {Map<string, { action: 'add' | 'update' | 'delete', oldValue: any }>}
   */
  get keys() {
    if (this._keys === null) {
      if (this.transaction.doc._transactionCleanups.length === 0) {
        throw create3(errorComputeChanges);
      }
      const keys2 = /* @__PURE__ */ new Map();
      const target = this.target;
      const changed = (
        /** @type Set<string|null> */
        this.transaction.changed.get(target)
      );
      changed.forEach((key2) => {
        if (key2 !== null) {
          const item = (
            /** @type {Item} */
            target._map.get(key2)
          );
          let action;
          let oldValue;
          if (this.adds(item)) {
            let prev = item.left;
            while (prev !== null && this.adds(prev)) {
              prev = prev.left;
            }
            if (this.deletes(item)) {
              if (prev !== null && this.deletes(prev)) {
                action = "delete";
                oldValue = last(prev.content.getContent());
              } else {
                return;
              }
            } else {
              if (prev !== null && this.deletes(prev)) {
                action = "update";
                oldValue = last(prev.content.getContent());
              } else {
                action = "add";
                oldValue = void 0;
              }
            }
          } else {
            if (this.deletes(item)) {
              action = "delete";
              oldValue = last(
                /** @type {Item} */
                item.content.getContent()
              );
            } else {
              return;
            }
          }
          keys2.set(key2, { action, oldValue });
        }
      });
      this._keys = keys2;
    }
    return this._keys;
  }
  /**
   * This is a computed property. Note that this can only be safely computed during the
   * event call. Computing this property after other changes happened might result in
   * unexpected behavior (incorrect computation of deltas). A safe way to collect changes
   * is to store the `changes` or the `delta` object. Avoid storing the `transaction` object.
   *
   * @type {Array<{insert?: string | Array<any> | object | AbstractType<any>, retain?: number, delete?: number, attributes?: Object<string, any>}>}
   */
  get delta() {
    return this.changes.delta;
  }
  /**
   * Check if a struct is added by this event.
   *
   * In contrast to change.deleted, this method also returns true if the struct was added and then deleted.
   *
   * @param {AbstractStruct} struct
   * @return {boolean}
   */
  adds(struct) {
    return struct.id.clock >= (this.transaction.beforeState.get(struct.id.client) || 0);
  }
  /**
   * This is a computed property. Note that this can only be safely computed during the
   * event call. Computing this property after other changes happened might result in
   * unexpected behavior (incorrect computation of deltas). A safe way to collect changes
   * is to store the `changes` or the `delta` object. Avoid storing the `transaction` object.
   *
   * @type {{added:Set<Item>,deleted:Set<Item>,keys:Map<string,{action:'add'|'update'|'delete',oldValue:any}>,delta:Array<{insert?:Array<any>|string, delete?:number, retain?:number}>}}
   */
  get changes() {
    let changes = this._changes;
    if (changes === null) {
      if (this.transaction.doc._transactionCleanups.length === 0) {
        throw create3(errorComputeChanges);
      }
      const target = this.target;
      const added = create2();
      const deleted = create2();
      const delta = [];
      changes = {
        added,
        deleted,
        delta,
        keys: this.keys
      };
      const changed = (
        /** @type Set<string|null> */
        this.transaction.changed.get(target)
      );
      if (changed.has(null)) {
        let lastOp = null;
        const packOp = () => {
          if (lastOp) {
            delta.push(lastOp);
          }
        };
        for (let item = target._start; item !== null; item = item.right) {
          if (item.deleted) {
            if (this.deletes(item) && !this.adds(item)) {
              if (lastOp === null || lastOp.delete === void 0) {
                packOp();
                lastOp = { delete: 0 };
              }
              lastOp.delete += item.length;
              deleted.add(item);
            }
          } else {
            if (this.adds(item)) {
              if (lastOp === null || lastOp.insert === void 0) {
                packOp();
                lastOp = { insert: [] };
              }
              lastOp.insert = lastOp.insert.concat(item.content.getContent());
              added.add(item);
            } else {
              if (lastOp === null || lastOp.retain === void 0) {
                packOp();
                lastOp = { retain: 0 };
              }
              lastOp.retain += item.length;
            }
          }
        }
        if (lastOp !== null && lastOp.retain === void 0) {
          packOp();
        }
      }
      this._changes = changes;
    }
    return (
      /** @type {any} */
      changes
    );
  }
};
var getPathTo = (parent, child) => {
  const path = [];
  while (child._item !== null && child !== parent) {
    if (child._item.parentSub !== null) {
      path.unshift(child._item.parentSub);
    } else {
      let i = 0;
      let c = (
        /** @type {AbstractType<any>} */
        child._item.parent._start
      );
      while (c !== child._item && c !== null) {
        if (!c.deleted && c.countable) {
          i += c.length;
        }
        c = c.right;
      }
      path.unshift(i);
    }
    child = /** @type {AbstractType<any>} */
    child._item.parent;
  }
  return path;
};
var warnPrematureAccess = () => {
  warn("Invalid access: Add Yjs type to a document before reading data.");
};
var maxSearchMarker = 80;
var globalSearchMarkerTimestamp = 0;
var ArraySearchMarker = class {
  /**
   * @param {Item} p
   * @param {number} index
   */
  constructor(p, index) {
    p.marker = true;
    this.p = p;
    this.index = index;
    this.timestamp = globalSearchMarkerTimestamp++;
  }
};
var refreshMarkerTimestamp = (marker) => {
  marker.timestamp = globalSearchMarkerTimestamp++;
};
var overwriteMarker = (marker, p, index) => {
  marker.p.marker = false;
  marker.p = p;
  p.marker = true;
  marker.index = index;
  marker.timestamp = globalSearchMarkerTimestamp++;
};
var markPosition = (searchMarker, p, index) => {
  if (searchMarker.length >= maxSearchMarker) {
    const marker = searchMarker.reduce((a, b) => a.timestamp < b.timestamp ? a : b);
    overwriteMarker(marker, p, index);
    return marker;
  } else {
    const pm = new ArraySearchMarker(p, index);
    searchMarker.push(pm);
    return pm;
  }
};
var findMarker = (yarray, index) => {
  if (yarray._start === null || index === 0 || yarray._searchMarker === null) {
    return null;
  }
  const marker = yarray._searchMarker.length === 0 ? null : yarray._searchMarker.reduce((a, b) => abs(index - a.index) < abs(index - b.index) ? a : b);
  let p = yarray._start;
  let pindex = 0;
  if (marker !== null) {
    p = marker.p;
    pindex = marker.index;
    refreshMarkerTimestamp(marker);
  }
  while (p.right !== null && pindex < index) {
    if (!p.deleted && p.countable) {
      if (index < pindex + p.length) {
        break;
      }
      pindex += p.length;
    }
    p = p.right;
  }
  while (p.left !== null && pindex > index) {
    p = p.left;
    if (!p.deleted && p.countable) {
      pindex -= p.length;
    }
  }
  while (p.left !== null && p.left.id.client === p.id.client && p.left.id.clock + p.left.length === p.id.clock) {
    p = p.left;
    if (!p.deleted && p.countable) {
      pindex -= p.length;
    }
  }
  if (marker !== null && abs(marker.index - pindex) < /** @type {YText|YArray<any>} */
  p.parent.length / maxSearchMarker) {
    overwriteMarker(marker, p, pindex);
    return marker;
  } else {
    return markPosition(yarray._searchMarker, p, pindex);
  }
};
var updateMarkerChanges = (searchMarker, index, len) => {
  for (let i = searchMarker.length - 1; i >= 0; i--) {
    const m = searchMarker[i];
    if (len > 0) {
      let p = m.p;
      p.marker = false;
      while (p && (p.deleted || !p.countable)) {
        p = p.left;
        if (p && !p.deleted && p.countable) {
          m.index -= p.length;
        }
      }
      if (p === null || p.marker === true) {
        searchMarker.splice(i, 1);
        continue;
      }
      m.p = p;
      p.marker = true;
    }
    if (index < m.index || len > 0 && index === m.index) {
      m.index = max(index, m.index + len);
    }
  }
};
var callTypeObservers = (type, transaction, event) => {
  const changedType = type;
  const changedParentTypes = transaction.changedParentTypes;
  while (true) {
    setIfUndefined(changedParentTypes, type, () => []).push(event);
    if (type._item === null) {
      break;
    }
    type = /** @type {AbstractType<any>} */
    type._item.parent;
  }
  callEventHandlerListeners(changedType._eH, event, transaction);
};
var AbstractType = class {
  constructor() {
    this._item = null;
    this._map = /* @__PURE__ */ new Map();
    this._start = null;
    this.doc = null;
    this._length = 0;
    this._eH = createEventHandler();
    this._dEH = createEventHandler();
    this._searchMarker = null;
  }
  /**
   * @return {AbstractType<any>|null}
   */
  get parent() {
    return this._item ? (
      /** @type {AbstractType<any>} */
      this._item.parent
    ) : null;
  }
  /**
   * Integrate this type into the Yjs instance.
   *
   * * Save this struct in the os
   * * This type is sent to other client
   * * Observer functions are fired
   *
   * @param {Doc} y The Yjs instance
   * @param {Item|null} item
   */
  _integrate(y, item) {
    this.doc = y;
    this._item = item;
  }
  /**
   * @return {AbstractType<EventType>}
   */
  _copy() {
    throw methodUnimplemented();
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {AbstractType<EventType>}
   */
  clone() {
    throw methodUnimplemented();
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} _encoder
   */
  _write(_encoder) {
  }
  /**
   * The first non-deleted item
   */
  get _first() {
    let n = this._start;
    while (n !== null && n.deleted) {
      n = n.right;
    }
    return n;
  }
  /**
   * Creates YEvent and calls all type observers.
   * Must be implemented by each type.
   *
   * @param {Transaction} transaction
   * @param {Set<null|string>} _parentSubs Keys changed on this type. `null` if list was modified.
   */
  _callObserver(transaction, _parentSubs) {
    if (!transaction.local && this._searchMarker) {
      this._searchMarker.length = 0;
    }
  }
  /**
   * Observe all events that are created on this type.
   *
   * @param {function(EventType, Transaction):void} f Observer function
   */
  observe(f) {
    addEventHandlerListener(this._eH, f);
  }
  /**
   * Observe all events that are created by this type and its children.
   *
   * @param {function(Array<YEvent<any>>,Transaction):void} f Observer function
   */
  observeDeep(f) {
    addEventHandlerListener(this._dEH, f);
  }
  /**
   * Unregister an observer function.
   *
   * @param {function(EventType,Transaction):void} f Observer function
   */
  unobserve(f) {
    removeEventHandlerListener(this._eH, f);
  }
  /**
   * Unregister an observer function.
   *
   * @param {function(Array<YEvent<any>>,Transaction):void} f Observer function
   */
  unobserveDeep(f) {
    removeEventHandlerListener(this._dEH, f);
  }
  /**
   * @abstract
   * @return {any}
   */
  toJSON() {
  }
};
var typeListSlice = (type, start, end) => {
  type.doc ?? warnPrematureAccess();
  if (start < 0) {
    start = type._length + start;
  }
  if (end < 0) {
    end = type._length + end;
  }
  let len = end - start;
  const cs = [];
  let n = type._start;
  while (n !== null && len > 0) {
    if (n.countable && !n.deleted) {
      const c = n.content.getContent();
      if (c.length <= start) {
        start -= c.length;
      } else {
        for (let i = start; i < c.length && len > 0; i++) {
          cs.push(c[i]);
          len--;
        }
        start = 0;
      }
    }
    n = n.right;
  }
  return cs;
};
var typeListToArray = (type) => {
  type.doc ?? warnPrematureAccess();
  const cs = [];
  let n = type._start;
  while (n !== null) {
    if (n.countable && !n.deleted) {
      const c = n.content.getContent();
      for (let i = 0; i < c.length; i++) {
        cs.push(c[i]);
      }
    }
    n = n.right;
  }
  return cs;
};
var typeListForEach = (type, f) => {
  let index = 0;
  let n = type._start;
  type.doc ?? warnPrematureAccess();
  while (n !== null) {
    if (n.countable && !n.deleted) {
      const c = n.content.getContent();
      for (let i = 0; i < c.length; i++) {
        f(c[i], index++, type);
      }
    }
    n = n.right;
  }
};
var typeListMap = (type, f) => {
  const result = [];
  typeListForEach(type, (c, i) => {
    result.push(f(c, i, type));
  });
  return result;
};
var typeListCreateIterator = (type) => {
  let n = type._start;
  let currentContent = null;
  let currentContentIndex = 0;
  return {
    [Symbol.iterator]() {
      return this;
    },
    next: () => {
      if (currentContent === null) {
        while (n !== null && n.deleted) {
          n = n.right;
        }
        if (n === null) {
          return {
            done: true,
            value: void 0
          };
        }
        currentContent = n.content.getContent();
        currentContentIndex = 0;
        n = n.right;
      }
      const value = currentContent[currentContentIndex++];
      if (currentContent.length <= currentContentIndex) {
        currentContent = null;
      }
      return {
        done: false,
        value
      };
    }
  };
};
var typeListGet = (type, index) => {
  type.doc ?? warnPrematureAccess();
  const marker = findMarker(type, index);
  let n = type._start;
  if (marker !== null) {
    n = marker.p;
    index -= marker.index;
  }
  for (; n !== null; n = n.right) {
    if (!n.deleted && n.countable) {
      if (index < n.length) {
        return n.content.getContent()[index];
      }
      index -= n.length;
    }
  }
};
var typeListInsertGenericsAfter = (transaction, parent, referenceItem, content) => {
  let left = referenceItem;
  const doc = transaction.doc;
  const ownClientId = doc.clientID;
  const store = doc.store;
  const right = referenceItem === null ? parent._start : referenceItem.right;
  let jsonContent = [];
  const packJsonContent = () => {
    if (jsonContent.length > 0) {
      left = new Item(createID(ownClientId, getState(store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, new ContentAny(jsonContent));
      left.integrate(transaction, 0);
      jsonContent = [];
    }
  };
  content.forEach((c) => {
    if (c === null) {
      jsonContent.push(c);
    } else {
      switch (c.constructor) {
        case Number:
        case Object:
        case Boolean:
        case Array:
        case String:
          jsonContent.push(c);
          break;
        default:
          packJsonContent();
          switch (c.constructor) {
            case Uint8Array:
            case ArrayBuffer:
              left = new Item(createID(ownClientId, getState(store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, new ContentBinary(new Uint8Array(
                /** @type {Uint8Array} */
                c
              )));
              left.integrate(transaction, 0);
              break;
            case Doc:
              left = new Item(createID(ownClientId, getState(store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, new ContentDoc(
                /** @type {Doc} */
                c
              ));
              left.integrate(transaction, 0);
              break;
            default:
              if (c instanceof AbstractType) {
                left = new Item(createID(ownClientId, getState(store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, new ContentType(c));
                left.integrate(transaction, 0);
              } else {
                throw new Error("Unexpected content type in insert operation");
              }
          }
      }
    }
  });
  packJsonContent();
};
var lengthExceeded = () => create3("Length exceeded!");
var typeListInsertGenerics = (transaction, parent, index, content) => {
  if (index > parent._length) {
    throw lengthExceeded();
  }
  if (index === 0) {
    if (parent._searchMarker) {
      updateMarkerChanges(parent._searchMarker, index, content.length);
    }
    return typeListInsertGenericsAfter(transaction, parent, null, content);
  }
  const startIndex = index;
  const marker = findMarker(parent, index);
  let n = parent._start;
  if (marker !== null) {
    n = marker.p;
    index -= marker.index;
    if (index === 0) {
      n = n.prev;
      index += n && n.countable && !n.deleted ? n.length : 0;
    }
  }
  for (; n !== null; n = n.right) {
    if (!n.deleted && n.countable) {
      if (index <= n.length) {
        if (index < n.length) {
          getItemCleanStart(transaction, createID(n.id.client, n.id.clock + index));
        }
        break;
      }
      index -= n.length;
    }
  }
  if (parent._searchMarker) {
    updateMarkerChanges(parent._searchMarker, startIndex, content.length);
  }
  return typeListInsertGenericsAfter(transaction, parent, n, content);
};
var typeListPushGenerics = (transaction, parent, content) => {
  const marker = (parent._searchMarker || []).reduce((maxMarker, currMarker) => currMarker.index > maxMarker.index ? currMarker : maxMarker, { index: 0, p: parent._start });
  let n = marker.p;
  if (n) {
    while (n.right) {
      n = n.right;
    }
  }
  return typeListInsertGenericsAfter(transaction, parent, n, content);
};
var typeListDelete = (transaction, parent, index, length2) => {
  if (length2 === 0) {
    return;
  }
  const startIndex = index;
  const startLength = length2;
  const marker = findMarker(parent, index);
  let n = parent._start;
  if (marker !== null) {
    n = marker.p;
    index -= marker.index;
  }
  for (; n !== null && index > 0; n = n.right) {
    if (!n.deleted && n.countable) {
      if (index < n.length) {
        getItemCleanStart(transaction, createID(n.id.client, n.id.clock + index));
      }
      index -= n.length;
    }
  }
  while (length2 > 0 && n !== null) {
    if (!n.deleted) {
      if (length2 < n.length) {
        getItemCleanStart(transaction, createID(n.id.client, n.id.clock + length2));
      }
      n.delete(transaction);
      length2 -= n.length;
    }
    n = n.right;
  }
  if (length2 > 0) {
    throw lengthExceeded();
  }
  if (parent._searchMarker) {
    updateMarkerChanges(
      parent._searchMarker,
      startIndex,
      -startLength + length2
      /* in case we remove the above exception */
    );
  }
};
var typeMapDelete = (transaction, parent, key2) => {
  const c = parent._map.get(key2);
  if (c !== void 0) {
    c.delete(transaction);
  }
};
var typeMapSet = (transaction, parent, key2, value) => {
  const left = parent._map.get(key2) || null;
  const doc = transaction.doc;
  const ownClientId = doc.clientID;
  let content;
  if (value == null) {
    content = new ContentAny([value]);
  } else {
    switch (value.constructor) {
      case Number:
      case Object:
      case Boolean:
      case Array:
      case String:
      case Date:
      case BigInt:
        content = new ContentAny([value]);
        break;
      case Uint8Array:
        content = new ContentBinary(
          /** @type {Uint8Array} */
          value
        );
        break;
      case Doc:
        content = new ContentDoc(
          /** @type {Doc} */
          value
        );
        break;
      default:
        if (value instanceof AbstractType) {
          content = new ContentType(value);
        } else {
          throw new Error("Unexpected content type");
        }
    }
  }
  new Item(createID(ownClientId, getState(doc.store, ownClientId)), left, left && left.lastId, null, null, parent, key2, content).integrate(transaction, 0);
};
var typeMapGet = (parent, key2) => {
  parent.doc ?? warnPrematureAccess();
  const val = parent._map.get(key2);
  return val !== void 0 && !val.deleted ? val.content.getContent()[val.length - 1] : void 0;
};
var typeMapGetAll = (parent) => {
  const res = {};
  parent.doc ?? warnPrematureAccess();
  parent._map.forEach((value, key2) => {
    if (!value.deleted) {
      res[key2] = value.content.getContent()[value.length - 1];
    }
  });
  return res;
};
var typeMapHas = (parent, key2) => {
  parent.doc ?? warnPrematureAccess();
  const val = parent._map.get(key2);
  return val !== void 0 && !val.deleted;
};
var typeMapGetAllSnapshot = (parent, snapshot) => {
  const res = {};
  parent._map.forEach((value, key2) => {
    let v = value;
    while (v !== null && (!snapshot.sv.has(v.id.client) || v.id.clock >= (snapshot.sv.get(v.id.client) || 0))) {
      v = v.left;
    }
    if (v !== null && isVisible(v, snapshot)) {
      res[key2] = v.content.getContent()[v.length - 1];
    }
  });
  return res;
};
var createMapIterator = (type) => {
  type.doc ?? warnPrematureAccess();
  return iteratorFilter(
    type._map.entries(),
    /** @param {any} entry */
    (entry) => !entry[1].deleted
  );
};
var YArrayEvent = class extends YEvent {
};
var YArray = class _YArray extends AbstractType {
  constructor() {
    super();
    this._prelimContent = [];
    this._searchMarker = [];
  }
  /**
   * Construct a new YArray containing the specified items.
   * @template {Object<string,any>|Array<any>|number|null|string|Uint8Array} T
   * @param {Array<T>} items
   * @return {YArray<T>}
   */
  static from(items) {
    const a = new _YArray();
    a.push(items);
    return a;
  }
  /**
   * Integrate this type into the Yjs instance.
   *
   * * Save this struct in the os
   * * This type is sent to other client
   * * Observer functions are fired
   *
   * @param {Doc} y The Yjs instance
   * @param {Item} item
   */
  _integrate(y, item) {
    super._integrate(y, item);
    this.insert(
      0,
      /** @type {Array<any>} */
      this._prelimContent
    );
    this._prelimContent = null;
  }
  /**
   * @return {YArray<T>}
   */
  _copy() {
    return new _YArray();
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YArray<T>}
   */
  clone() {
    const arr = new _YArray();
    arr.insert(0, this.toArray().map(
      (el) => el instanceof AbstractType ? (
        /** @type {typeof el} */
        el.clone()
      ) : el
    ));
    return arr;
  }
  get length() {
    this.doc ?? warnPrematureAccess();
    return this._length;
  }
  /**
   * Creates YArrayEvent and calls observers.
   *
   * @param {Transaction} transaction
   * @param {Set<null|string>} parentSubs Keys changed on this type. `null` if list was modified.
   */
  _callObserver(transaction, parentSubs) {
    super._callObserver(transaction, parentSubs);
    callTypeObservers(this, transaction, new YArrayEvent(this, transaction));
  }
  /**
   * Inserts new content at an index.
   *
   * Important: This function expects an array of content. Not just a content
   * object. The reason for this "weirdness" is that inserting several elements
   * is very efficient when it is done as a single operation.
   *
   * @example
   *  // Insert character 'a' at position 0
   *  yarray.insert(0, ['a'])
   *  // Insert numbers 1, 2 at position 1
   *  yarray.insert(1, [1, 2])
   *
   * @param {number} index The index to insert content at.
   * @param {Array<T>} content The array of content
   */
  insert(index, content) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeListInsertGenerics(
          transaction,
          this,
          index,
          /** @type {any} */
          content
        );
      });
    } else {
      this._prelimContent.splice(index, 0, ...content);
    }
  }
  /**
   * Appends content to this YArray.
   *
   * @param {Array<T>} content Array of content to append.
   *
   * @todo Use the following implementation in all types.
   */
  push(content) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeListPushGenerics(
          transaction,
          this,
          /** @type {any} */
          content
        );
      });
    } else {
      this._prelimContent.push(...content);
    }
  }
  /**
   * Prepends content to this YArray.
   *
   * @param {Array<T>} content Array of content to prepend.
   */
  unshift(content) {
    this.insert(0, content);
  }
  /**
   * Deletes elements starting from an index.
   *
   * @param {number} index Index at which to start deleting elements
   * @param {number} length The number of elements to remove. Defaults to 1.
   */
  delete(index, length2 = 1) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeListDelete(transaction, this, index, length2);
      });
    } else {
      this._prelimContent.splice(index, length2);
    }
  }
  /**
   * Returns the i-th element from a YArray.
   *
   * @param {number} index The index of the element to return from the YArray
   * @return {T}
   */
  get(index) {
    return typeListGet(this, index);
  }
  /**
   * Transforms this YArray to a JavaScript Array.
   *
   * @return {Array<T>}
   */
  toArray() {
    return typeListToArray(this);
  }
  /**
   * Returns a portion of this YArray into a JavaScript Array selected
   * from start to end (end not included).
   *
   * @param {number} [start]
   * @param {number} [end]
   * @return {Array<T>}
   */
  slice(start = 0, end = this.length) {
    return typeListSlice(this, start, end);
  }
  /**
   * Transforms this Shared Type to a JSON object.
   *
   * @return {Array<any>}
   */
  toJSON() {
    return this.map((c) => c instanceof AbstractType ? c.toJSON() : c);
  }
  /**
   * Returns an Array with the result of calling a provided function on every
   * element of this YArray.
   *
   * @template M
   * @param {function(T,number,YArray<T>):M} f Function that produces an element of the new Array
   * @return {Array<M>} A new array with each element being the result of the
   *                 callback function
   */
  map(f) {
    return typeListMap(
      this,
      /** @type {any} */
      f
    );
  }
  /**
   * Executes a provided function once on every element of this YArray.
   *
   * @param {function(T,number,YArray<T>):void} f A function to execute on every element of this YArray.
   */
  forEach(f) {
    typeListForEach(this, f);
  }
  /**
   * @return {IterableIterator<T>}
   */
  [Symbol.iterator]() {
    return typeListCreateIterator(this);
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   */
  _write(encoder) {
    encoder.writeTypeRef(YArrayRefID);
  }
};
var readYArray = (_decoder) => new YArray();
var YMapEvent = class extends YEvent {
  /**
   * @param {YMap<T>} ymap The YArray that changed.
   * @param {Transaction} transaction
   * @param {Set<any>} subs The keys that changed.
   */
  constructor(ymap, transaction, subs) {
    super(ymap, transaction);
    this.keysChanged = subs;
  }
};
var YMap = class _YMap extends AbstractType {
  /**
   *
   * @param {Iterable<readonly [string, any]>=} entries - an optional iterable to initialize the YMap
   */
  constructor(entries) {
    super();
    this._prelimContent = null;
    if (entries === void 0) {
      this._prelimContent = /* @__PURE__ */ new Map();
    } else {
      this._prelimContent = new Map(entries);
    }
  }
  /**
   * Integrate this type into the Yjs instance.
   *
   * * Save this struct in the os
   * * This type is sent to other client
   * * Observer functions are fired
   *
   * @param {Doc} y The Yjs instance
   * @param {Item} item
   */
  _integrate(y, item) {
    super._integrate(y, item);
    this._prelimContent.forEach((value, key2) => {
      this.set(key2, value);
    });
    this._prelimContent = null;
  }
  /**
   * @return {YMap<MapType>}
   */
  _copy() {
    return new _YMap();
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YMap<MapType>}
   */
  clone() {
    const map3 = new _YMap();
    this.forEach((value, key2) => {
      map3.set(key2, value instanceof AbstractType ? (
        /** @type {typeof value} */
        value.clone()
      ) : value);
    });
    return map3;
  }
  /**
   * Creates YMapEvent and calls observers.
   *
   * @param {Transaction} transaction
   * @param {Set<null|string>} parentSubs Keys changed on this type. `null` if list was modified.
   */
  _callObserver(transaction, parentSubs) {
    callTypeObservers(this, transaction, new YMapEvent(this, transaction, parentSubs));
  }
  /**
   * Transforms this Shared Type to a JSON object.
   *
   * @return {Object<string,any>}
   */
  toJSON() {
    this.doc ?? warnPrematureAccess();
    const map3 = {};
    this._map.forEach((item, key2) => {
      if (!item.deleted) {
        const v = item.content.getContent()[item.length - 1];
        map3[key2] = v instanceof AbstractType ? v.toJSON() : v;
      }
    });
    return map3;
  }
  /**
   * Returns the size of the YMap (count of key/value pairs)
   *
   * @return {number}
   */
  get size() {
    return [...createMapIterator(this)].length;
  }
  /**
   * Returns the keys for each element in the YMap Type.
   *
   * @return {IterableIterator<string>}
   */
  keys() {
    return iteratorMap(
      createMapIterator(this),
      /** @param {any} v */
      (v) => v[0]
    );
  }
  /**
   * Returns the values for each element in the YMap Type.
   *
   * @return {IterableIterator<MapType>}
   */
  values() {
    return iteratorMap(
      createMapIterator(this),
      /** @param {any} v */
      (v) => v[1].content.getContent()[v[1].length - 1]
    );
  }
  /**
   * Returns an Iterator of [key, value] pairs
   *
   * @return {IterableIterator<[string, MapType]>}
   */
  entries() {
    return iteratorMap(
      createMapIterator(this),
      /** @param {any} v */
      (v) => (
        /** @type {any} */
        [v[0], v[1].content.getContent()[v[1].length - 1]]
      )
    );
  }
  /**
   * Executes a provided function on once on every key-value pair.
   *
   * @param {function(MapType,string,YMap<MapType>):void} f A function to execute on every element of this YArray.
   */
  forEach(f) {
    this.doc ?? warnPrematureAccess();
    this._map.forEach((item, key2) => {
      if (!item.deleted) {
        f(item.content.getContent()[item.length - 1], key2, this);
      }
    });
  }
  /**
   * Returns an Iterator of [key, value] pairs
   *
   * @return {IterableIterator<[string, MapType]>}
   */
  [Symbol.iterator]() {
    return this.entries();
  }
  /**
   * Remove a specified element from this YMap.
   *
   * @param {string} key The key of the element to remove.
   */
  delete(key2) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeMapDelete(transaction, this, key2);
      });
    } else {
      this._prelimContent.delete(key2);
    }
  }
  /**
   * Adds or updates an element with a specified key and value.
   * @template {MapType} VAL
   *
   * @param {string} key The key of the element to add to this YMap
   * @param {VAL} value The value of the element to add
   * @return {VAL}
   */
  set(key2, value) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeMapSet(
          transaction,
          this,
          key2,
          /** @type {any} */
          value
        );
      });
    } else {
      this._prelimContent.set(key2, value);
    }
    return value;
  }
  /**
   * Returns a specified element from this YMap.
   *
   * @param {string} key
   * @return {MapType|undefined}
   */
  get(key2) {
    return (
      /** @type {any} */
      typeMapGet(this, key2)
    );
  }
  /**
   * Returns a boolean indicating whether the specified key exists or not.
   *
   * @param {string} key The key to test.
   * @return {boolean}
   */
  has(key2) {
    return typeMapHas(this, key2);
  }
  /**
   * Removes all elements from this YMap.
   */
  clear() {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        this.forEach(function(_value, key2, map3) {
          typeMapDelete(transaction, map3, key2);
        });
      });
    } else {
      this._prelimContent.clear();
    }
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   */
  _write(encoder) {
    encoder.writeTypeRef(YMapRefID);
  }
};
var readYMap = (_decoder) => new YMap();
var equalAttrs = (a, b) => a === b || typeof a === "object" && typeof b === "object" && a && b && equalFlat(a, b);
var ItemTextListPosition = class {
  /**
   * @param {Item|null} left
   * @param {Item|null} right
   * @param {number} index
   * @param {Map<string,any>} currentAttributes
   */
  constructor(left, right, index, currentAttributes) {
    this.left = left;
    this.right = right;
    this.index = index;
    this.currentAttributes = currentAttributes;
  }
  /**
   * Only call this if you know that this.right is defined
   */
  forward() {
    if (this.right === null) {
      unexpectedCase();
    }
    switch (this.right.content.constructor) {
      case ContentFormat:
        if (!this.right.deleted) {
          updateCurrentAttributes(
            this.currentAttributes,
            /** @type {ContentFormat} */
            this.right.content
          );
        }
        break;
      default:
        if (!this.right.deleted) {
          this.index += this.right.length;
        }
        break;
    }
    this.left = this.right;
    this.right = this.right.right;
  }
};
var findNextPosition = (transaction, pos, count) => {
  while (pos.right !== null && count > 0) {
    switch (pos.right.content.constructor) {
      case ContentFormat:
        if (!pos.right.deleted) {
          updateCurrentAttributes(
            pos.currentAttributes,
            /** @type {ContentFormat} */
            pos.right.content
          );
        }
        break;
      default:
        if (!pos.right.deleted) {
          if (count < pos.right.length) {
            getItemCleanStart(transaction, createID(pos.right.id.client, pos.right.id.clock + count));
          }
          pos.index += pos.right.length;
          count -= pos.right.length;
        }
        break;
    }
    pos.left = pos.right;
    pos.right = pos.right.right;
  }
  return pos;
};
var findPosition = (transaction, parent, index, useSearchMarker) => {
  const currentAttributes = /* @__PURE__ */ new Map();
  const marker = useSearchMarker ? findMarker(parent, index) : null;
  if (marker) {
    const pos = new ItemTextListPosition(marker.p.left, marker.p, marker.index, currentAttributes);
    return findNextPosition(transaction, pos, index - marker.index);
  } else {
    const pos = new ItemTextListPosition(null, parent._start, 0, currentAttributes);
    return findNextPosition(transaction, pos, index);
  }
};
var insertNegatedAttributes = (transaction, parent, currPos, negatedAttributes) => {
  while (currPos.right !== null && (currPos.right.deleted === true || currPos.right.content.constructor === ContentFormat && equalAttrs(
    negatedAttributes.get(
      /** @type {ContentFormat} */
      currPos.right.content.key
    ),
    /** @type {ContentFormat} */
    currPos.right.content.value
  ))) {
    if (!currPos.right.deleted) {
      negatedAttributes.delete(
        /** @type {ContentFormat} */
        currPos.right.content.key
      );
    }
    currPos.forward();
  }
  const doc = transaction.doc;
  const ownClientId = doc.clientID;
  negatedAttributes.forEach((val, key2) => {
    const left = currPos.left;
    const right = currPos.right;
    const nextFormat = new Item(createID(ownClientId, getState(doc.store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, new ContentFormat(key2, val));
    nextFormat.integrate(transaction, 0);
    currPos.right = nextFormat;
    currPos.forward();
  });
};
var updateCurrentAttributes = (currentAttributes, format) => {
  const { key: key2, value } = format;
  if (value === null) {
    currentAttributes.delete(key2);
  } else {
    currentAttributes.set(key2, value);
  }
};
var minimizeAttributeChanges = (currPos, attributes) => {
  while (true) {
    if (currPos.right === null) {
      break;
    } else if (currPos.right.deleted || currPos.right.content.constructor === ContentFormat && equalAttrs(
      attributes[
        /** @type {ContentFormat} */
        currPos.right.content.key
      ] ?? null,
      /** @type {ContentFormat} */
      currPos.right.content.value
    )) ;
    else {
      break;
    }
    currPos.forward();
  }
};
var insertAttributes = (transaction, parent, currPos, attributes) => {
  const doc = transaction.doc;
  const ownClientId = doc.clientID;
  const negatedAttributes = /* @__PURE__ */ new Map();
  for (const key2 in attributes) {
    const val = attributes[key2];
    const currentVal = currPos.currentAttributes.get(key2) ?? null;
    if (!equalAttrs(currentVal, val)) {
      negatedAttributes.set(key2, currentVal);
      const { left, right } = currPos;
      currPos.right = new Item(createID(ownClientId, getState(doc.store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, new ContentFormat(key2, val));
      currPos.right.integrate(transaction, 0);
      currPos.forward();
    }
  }
  return negatedAttributes;
};
var insertText = (transaction, parent, currPos, text, attributes) => {
  currPos.currentAttributes.forEach((_val, key2) => {
    if (attributes[key2] === void 0) {
      attributes[key2] = null;
    }
  });
  const doc = transaction.doc;
  const ownClientId = doc.clientID;
  minimizeAttributeChanges(currPos, attributes);
  const negatedAttributes = insertAttributes(transaction, parent, currPos, attributes);
  const content = text.constructor === String ? new ContentString(
    /** @type {string} */
    text
  ) : text instanceof AbstractType ? new ContentType(text) : new ContentEmbed(text);
  let { left, right, index } = currPos;
  if (parent._searchMarker) {
    updateMarkerChanges(parent._searchMarker, currPos.index, content.getLength());
  }
  right = new Item(createID(ownClientId, getState(doc.store, ownClientId)), left, left && left.lastId, right, right && right.id, parent, null, content);
  right.integrate(transaction, 0);
  currPos.right = right;
  currPos.index = index;
  currPos.forward();
  insertNegatedAttributes(transaction, parent, currPos, negatedAttributes);
};
var formatText = (transaction, parent, currPos, length2, attributes) => {
  const doc = transaction.doc;
  const ownClientId = doc.clientID;
  minimizeAttributeChanges(currPos, attributes);
  const negatedAttributes = insertAttributes(transaction, parent, currPos, attributes);
  iterationLoop: while (currPos.right !== null && (length2 > 0 || negatedAttributes.size > 0 && (currPos.right.deleted || currPos.right.content.constructor === ContentFormat))) {
    if (!currPos.right.deleted) {
      switch (currPos.right.content.constructor) {
        case ContentFormat: {
          const { key: key2, value } = (
            /** @type {ContentFormat} */
            currPos.right.content
          );
          const attr = attributes[key2];
          if (attr !== void 0) {
            if (equalAttrs(attr, value)) {
              negatedAttributes.delete(key2);
            } else {
              if (length2 === 0) {
                break iterationLoop;
              }
              negatedAttributes.set(key2, value);
            }
            currPos.right.delete(transaction);
          } else {
            currPos.currentAttributes.set(key2, value);
          }
          break;
        }
        default:
          if (length2 < currPos.right.length) {
            getItemCleanStart(transaction, createID(currPos.right.id.client, currPos.right.id.clock + length2));
          }
          length2 -= currPos.right.length;
          break;
      }
    }
    currPos.forward();
  }
  if (length2 > 0) {
    let newlines = "";
    for (; length2 > 0; length2--) {
      newlines += "\n";
    }
    currPos.right = new Item(createID(ownClientId, getState(doc.store, ownClientId)), currPos.left, currPos.left && currPos.left.lastId, currPos.right, currPos.right && currPos.right.id, parent, null, new ContentString(newlines));
    currPos.right.integrate(transaction, 0);
    currPos.forward();
  }
  insertNegatedAttributes(transaction, parent, currPos, negatedAttributes);
};
var cleanupFormattingGap = (transaction, start, curr, startAttributes, currAttributes) => {
  let end = start;
  const endFormats = create();
  while (end && (!end.countable || end.deleted)) {
    if (!end.deleted && end.content.constructor === ContentFormat) {
      const cf = (
        /** @type {ContentFormat} */
        end.content
      );
      endFormats.set(cf.key, cf);
    }
    end = end.right;
  }
  let cleanups = 0;
  let reachedCurr = false;
  while (start !== end) {
    if (curr === start) {
      reachedCurr = true;
    }
    if (!start.deleted) {
      const content = start.content;
      switch (content.constructor) {
        case ContentFormat: {
          const { key: key2, value } = (
            /** @type {ContentFormat} */
            content
          );
          const startAttrValue = startAttributes.get(key2) ?? null;
          if (endFormats.get(key2) !== content || startAttrValue === value) {
            start.delete(transaction);
            cleanups++;
            if (!reachedCurr && (currAttributes.get(key2) ?? null) === value && startAttrValue !== value) {
              if (startAttrValue === null) {
                currAttributes.delete(key2);
              } else {
                currAttributes.set(key2, startAttrValue);
              }
            }
          }
          if (!reachedCurr && !start.deleted) {
            updateCurrentAttributes(
              currAttributes,
              /** @type {ContentFormat} */
              content
            );
          }
          break;
        }
      }
    }
    start = /** @type {Item} */
    start.right;
  }
  return cleanups;
};
var cleanupContextlessFormattingGap = (transaction, item) => {
  while (item && item.right && (item.right.deleted || !item.right.countable)) {
    item = item.right;
  }
  const attrs = /* @__PURE__ */ new Set();
  while (item && (item.deleted || !item.countable)) {
    if (!item.deleted && item.content.constructor === ContentFormat) {
      const key2 = (
        /** @type {ContentFormat} */
        item.content.key
      );
      if (attrs.has(key2)) {
        item.delete(transaction);
      } else {
        attrs.add(key2);
      }
    }
    item = item.left;
  }
};
var cleanupYTextFormatting = (type) => {
  let res = 0;
  transact(
    /** @type {Doc} */
    type.doc,
    (transaction) => {
      let start = (
        /** @type {Item} */
        type._start
      );
      let end = type._start;
      let startAttributes = create();
      const currentAttributes = copy(startAttributes);
      while (end) {
        if (end.deleted === false) {
          switch (end.content.constructor) {
            case ContentFormat:
              updateCurrentAttributes(
                currentAttributes,
                /** @type {ContentFormat} */
                end.content
              );
              break;
            default:
              res += cleanupFormattingGap(transaction, start, end, startAttributes, currentAttributes);
              startAttributes = copy(currentAttributes);
              start = end;
              break;
          }
        }
        end = end.right;
      }
    }
  );
  return res;
};
var cleanupYTextAfterTransaction = (transaction) => {
  const needFullCleanup = /* @__PURE__ */ new Set();
  const doc = transaction.doc;
  for (const [client, afterClock] of transaction.afterState.entries()) {
    const clock = transaction.beforeState.get(client) || 0;
    if (afterClock === clock) {
      continue;
    }
    iterateStructs(
      transaction,
      /** @type {Array<Item|GC>} */
      doc.store.clients.get(client),
      clock,
      afterClock,
      (item) => {
        if (!item.deleted && /** @type {Item} */
        item.content.constructor === ContentFormat && item.constructor !== GC) {
          needFullCleanup.add(
            /** @type {any} */
            item.parent
          );
        }
      }
    );
  }
  transact(doc, (t) => {
    iterateDeletedStructs(transaction, transaction.deleteSet, (item) => {
      if (item instanceof GC || !/** @type {YText} */
      item.parent._hasFormatting || needFullCleanup.has(
        /** @type {YText} */
        item.parent
      )) {
        return;
      }
      const parent = (
        /** @type {YText} */
        item.parent
      );
      if (item.content.constructor === ContentFormat) {
        needFullCleanup.add(parent);
      } else {
        cleanupContextlessFormattingGap(t, item);
      }
    });
    for (const yText of needFullCleanup) {
      cleanupYTextFormatting(yText);
    }
  });
};
var deleteText = (transaction, currPos, length2) => {
  const startLength = length2;
  const startAttrs = copy(currPos.currentAttributes);
  const start = currPos.right;
  while (length2 > 0 && currPos.right !== null) {
    if (currPos.right.deleted === false) {
      switch (currPos.right.content.constructor) {
        case ContentType:
        case ContentEmbed:
        case ContentString:
          if (length2 < currPos.right.length) {
            getItemCleanStart(transaction, createID(currPos.right.id.client, currPos.right.id.clock + length2));
          }
          length2 -= currPos.right.length;
          currPos.right.delete(transaction);
          break;
      }
    }
    currPos.forward();
  }
  if (start) {
    cleanupFormattingGap(transaction, start, currPos.right, startAttrs, currPos.currentAttributes);
  }
  const parent = (
    /** @type {AbstractType<any>} */
    /** @type {Item} */
    (currPos.left || currPos.right).parent
  );
  if (parent._searchMarker) {
    updateMarkerChanges(parent._searchMarker, currPos.index, -startLength + length2);
  }
  return currPos;
};
var YTextEvent = class extends YEvent {
  /**
   * @param {YText} ytext
   * @param {Transaction} transaction
   * @param {Set<any>} subs The keys that changed
   */
  constructor(ytext, transaction, subs) {
    super(ytext, transaction);
    this.childListChanged = false;
    this.keysChanged = /* @__PURE__ */ new Set();
    subs.forEach((sub) => {
      if (sub === null) {
        this.childListChanged = true;
      } else {
        this.keysChanged.add(sub);
      }
    });
  }
  /**
   * @type {{added:Set<Item>,deleted:Set<Item>,keys:Map<string,{action:'add'|'update'|'delete',oldValue:any}>,delta:Array<{insert?:Array<any>|string, delete?:number, retain?:number}>}}
   */
  get changes() {
    if (this._changes === null) {
      const changes = {
        keys: this.keys,
        delta: this.delta,
        added: /* @__PURE__ */ new Set(),
        deleted: /* @__PURE__ */ new Set()
      };
      this._changes = changes;
    }
    return (
      /** @type {any} */
      this._changes
    );
  }
  /**
   * Compute the changes in the delta format.
   * A {@link https://quilljs.com/docs/delta/|Quill Delta}) that represents the changes on the document.
   *
   * @type {Array<{insert?:string|object|AbstractType<any>, delete?:number, retain?:number, attributes?: Object<string,any>}>}
   *
   * @public
   */
  get delta() {
    if (this._delta === null) {
      const y = (
        /** @type {Doc} */
        this.target.doc
      );
      const delta = [];
      transact(y, (transaction) => {
        const currentAttributes = /* @__PURE__ */ new Map();
        const oldAttributes = /* @__PURE__ */ new Map();
        let item = this.target._start;
        let action = null;
        const attributes = {};
        let insert = "";
        let retain = 0;
        let deleteLen = 0;
        const addOp = () => {
          if (action !== null) {
            let op = null;
            switch (action) {
              case "delete":
                if (deleteLen > 0) {
                  op = { delete: deleteLen };
                }
                deleteLen = 0;
                break;
              case "insert":
                if (typeof insert === "object" || insert.length > 0) {
                  op = { insert };
                  if (currentAttributes.size > 0) {
                    op.attributes = {};
                    currentAttributes.forEach((value, key2) => {
                      if (value !== null) {
                        op.attributes[key2] = value;
                      }
                    });
                  }
                }
                insert = "";
                break;
              case "retain":
                if (retain > 0) {
                  op = { retain };
                  if (!isEmpty(attributes)) {
                    op.attributes = assign({}, attributes);
                  }
                }
                retain = 0;
                break;
            }
            if (op) delta.push(op);
            action = null;
          }
        };
        while (item !== null) {
          switch (item.content.constructor) {
            case ContentType:
            case ContentEmbed:
              if (this.adds(item)) {
                if (!this.deletes(item)) {
                  addOp();
                  action = "insert";
                  insert = item.content.getContent()[0];
                  addOp();
                }
              } else if (this.deletes(item)) {
                if (action !== "delete") {
                  addOp();
                  action = "delete";
                }
                deleteLen += 1;
              } else if (!item.deleted) {
                if (action !== "retain") {
                  addOp();
                  action = "retain";
                }
                retain += 1;
              }
              break;
            case ContentString:
              if (this.adds(item)) {
                if (!this.deletes(item)) {
                  if (action !== "insert") {
                    addOp();
                    action = "insert";
                  }
                  insert += /** @type {ContentString} */
                  item.content.str;
                }
              } else if (this.deletes(item)) {
                if (action !== "delete") {
                  addOp();
                  action = "delete";
                }
                deleteLen += item.length;
              } else if (!item.deleted) {
                if (action !== "retain") {
                  addOp();
                  action = "retain";
                }
                retain += item.length;
              }
              break;
            case ContentFormat: {
              const { key: key2, value } = (
                /** @type {ContentFormat} */
                item.content
              );
              if (this.adds(item)) {
                if (!this.deletes(item)) {
                  const curVal = currentAttributes.get(key2) ?? null;
                  if (!equalAttrs(curVal, value)) {
                    if (action === "retain") {
                      addOp();
                    }
                    if (equalAttrs(value, oldAttributes.get(key2) ?? null)) {
                      delete attributes[key2];
                    } else {
                      attributes[key2] = value;
                    }
                  } else if (value !== null) {
                    item.delete(transaction);
                  }
                }
              } else if (this.deletes(item)) {
                oldAttributes.set(key2, value);
                const curVal = currentAttributes.get(key2) ?? null;
                if (!equalAttrs(curVal, value)) {
                  if (action === "retain") {
                    addOp();
                  }
                  attributes[key2] = curVal;
                }
              } else if (!item.deleted) {
                oldAttributes.set(key2, value);
                const attr = attributes[key2];
                if (attr !== void 0) {
                  if (!equalAttrs(attr, value)) {
                    if (action === "retain") {
                      addOp();
                    }
                    if (value === null) {
                      delete attributes[key2];
                    } else {
                      attributes[key2] = value;
                    }
                  } else if (attr !== null) {
                    item.delete(transaction);
                  }
                }
              }
              if (!item.deleted) {
                if (action === "insert") {
                  addOp();
                }
                updateCurrentAttributes(
                  currentAttributes,
                  /** @type {ContentFormat} */
                  item.content
                );
              }
              break;
            }
          }
          item = item.right;
        }
        addOp();
        while (delta.length > 0) {
          const lastOp = delta[delta.length - 1];
          if (lastOp.retain !== void 0 && lastOp.attributes === void 0) {
            delta.pop();
          } else {
            break;
          }
        }
      });
      this._delta = delta;
    }
    return (
      /** @type {any} */
      this._delta
    );
  }
};
var YText = class _YText extends AbstractType {
  /**
   * @param {String} [string] The initial value of the YText.
   */
  constructor(string) {
    super();
    this._pending = string !== void 0 ? [() => this.insert(0, string)] : [];
    this._searchMarker = [];
    this._hasFormatting = false;
  }
  /**
   * Number of characters of this text type.
   *
   * @type {number}
   */
  get length() {
    this.doc ?? warnPrematureAccess();
    return this._length;
  }
  /**
   * @param {Doc} y
   * @param {Item} item
   */
  _integrate(y, item) {
    super._integrate(y, item);
    try {
      this._pending.forEach((f) => f());
    } catch (e) {
      console.error(e);
    }
    this._pending = null;
  }
  _copy() {
    return new _YText();
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YText}
   */
  clone() {
    const text = new _YText();
    text.applyDelta(this.toDelta());
    return text;
  }
  /**
   * Creates YTextEvent and calls observers.
   *
   * @param {Transaction} transaction
   * @param {Set<null|string>} parentSubs Keys changed on this type. `null` if list was modified.
   */
  _callObserver(transaction, parentSubs) {
    super._callObserver(transaction, parentSubs);
    const event = new YTextEvent(this, transaction, parentSubs);
    callTypeObservers(this, transaction, event);
    if (!transaction.local && this._hasFormatting) {
      transaction._needFormattingCleanup = true;
    }
  }
  /**
   * Returns the unformatted string representation of this YText type.
   *
   * @public
   */
  toString() {
    this.doc ?? warnPrematureAccess();
    let str2 = "";
    let n = this._start;
    while (n !== null) {
      if (!n.deleted && n.countable && n.content.constructor === ContentString) {
        str2 += /** @type {ContentString} */
        n.content.str;
      }
      n = n.right;
    }
    return str2;
  }
  /**
   * Returns the unformatted string representation of this YText type.
   *
   * @return {string}
   * @public
   */
  toJSON() {
    return this.toString();
  }
  /**
   * Apply a {@link Delta} on this shared YText type.
   *
   * @param {Array<any>} delta The changes to apply on this element.
   * @param {object}  opts
   * @param {boolean} [opts.sanitize] Sanitize input delta. Removes ending newlines if set to true.
   *
   *
   * @public
   */
  applyDelta(delta, { sanitize = true } = {}) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        const currPos = new ItemTextListPosition(null, this._start, 0, /* @__PURE__ */ new Map());
        for (let i = 0; i < delta.length; i++) {
          const op = delta[i];
          if (op.insert !== void 0) {
            const ins = !sanitize && typeof op.insert === "string" && i === delta.length - 1 && currPos.right === null && op.insert.slice(-1) === "\n" ? op.insert.slice(0, -1) : op.insert;
            if (typeof ins !== "string" || ins.length > 0) {
              insertText(transaction, this, currPos, ins, op.attributes || {});
            }
          } else if (op.retain !== void 0) {
            formatText(transaction, this, currPos, op.retain, op.attributes || {});
          } else if (op.delete !== void 0) {
            deleteText(transaction, currPos, op.delete);
          }
        }
      });
    } else {
      this._pending.push(() => this.applyDelta(delta));
    }
  }
  /**
   * Returns the Delta representation of this YText type.
   *
   * @param {Snapshot} [snapshot]
   * @param {Snapshot} [prevSnapshot]
   * @param {function('removed' | 'added', ID):any} [computeYChange]
   * @return {any} The Delta representation of this type.
   *
   * @public
   */
  toDelta(snapshot, prevSnapshot, computeYChange) {
    this.doc ?? warnPrematureAccess();
    const ops = [];
    const currentAttributes = /* @__PURE__ */ new Map();
    const doc = (
      /** @type {Doc} */
      this.doc
    );
    let str2 = "";
    let n = this._start;
    function packStr() {
      if (str2.length > 0) {
        const attributes = {};
        let addAttributes = false;
        currentAttributes.forEach((value, key2) => {
          addAttributes = true;
          attributes[key2] = value;
        });
        const op = { insert: str2 };
        if (addAttributes) {
          op.attributes = attributes;
        }
        ops.push(op);
        str2 = "";
      }
    }
    const computeDelta = () => {
      while (n !== null) {
        if (isVisible(n, snapshot) || prevSnapshot !== void 0 && isVisible(n, prevSnapshot)) {
          switch (n.content.constructor) {
            case ContentString: {
              const cur = currentAttributes.get("ychange");
              if (snapshot !== void 0 && !isVisible(n, snapshot)) {
                if (cur === void 0 || cur.user !== n.id.client || cur.type !== "removed") {
                  packStr();
                  currentAttributes.set("ychange", computeYChange ? computeYChange("removed", n.id) : { type: "removed" });
                }
              } else if (prevSnapshot !== void 0 && !isVisible(n, prevSnapshot)) {
                if (cur === void 0 || cur.user !== n.id.client || cur.type !== "added") {
                  packStr();
                  currentAttributes.set("ychange", computeYChange ? computeYChange("added", n.id) : { type: "added" });
                }
              } else if (cur !== void 0) {
                packStr();
                currentAttributes.delete("ychange");
              }
              str2 += /** @type {ContentString} */
              n.content.str;
              break;
            }
            case ContentType:
            case ContentEmbed: {
              packStr();
              const op = {
                insert: n.content.getContent()[0]
              };
              if (currentAttributes.size > 0) {
                const attrs = (
                  /** @type {Object<string,any>} */
                  {}
                );
                op.attributes = attrs;
                currentAttributes.forEach((value, key2) => {
                  attrs[key2] = value;
                });
              }
              ops.push(op);
              break;
            }
            case ContentFormat:
              if (isVisible(n, snapshot)) {
                packStr();
                updateCurrentAttributes(
                  currentAttributes,
                  /** @type {ContentFormat} */
                  n.content
                );
              }
              break;
          }
        }
        n = n.right;
      }
      packStr();
    };
    if (snapshot || prevSnapshot) {
      transact(doc, (transaction) => {
        if (snapshot) {
          splitSnapshotAffectedStructs(transaction, snapshot);
        }
        if (prevSnapshot) {
          splitSnapshotAffectedStructs(transaction, prevSnapshot);
        }
        computeDelta();
      }, "cleanup");
    } else {
      computeDelta();
    }
    return ops;
  }
  /**
   * Insert text at a given index.
   *
   * @param {number} index The index at which to start inserting.
   * @param {String} text The text to insert at the specified position.
   * @param {TextAttributes} [attributes] Optionally define some formatting
   *                                    information to apply on the inserted
   *                                    Text.
   * @public
   */
  insert(index, text, attributes) {
    if (text.length <= 0) {
      return;
    }
    const y = this.doc;
    if (y !== null) {
      transact(y, (transaction) => {
        const pos = findPosition(transaction, this, index, !attributes);
        if (!attributes) {
          attributes = {};
          pos.currentAttributes.forEach((v, k) => {
            attributes[k] = v;
          });
        }
        insertText(transaction, this, pos, text, attributes);
      });
    } else {
      this._pending.push(() => this.insert(index, text, attributes));
    }
  }
  /**
   * Inserts an embed at a index.
   *
   * @param {number} index The index to insert the embed at.
   * @param {Object | AbstractType<any>} embed The Object that represents the embed.
   * @param {TextAttributes} [attributes] Attribute information to apply on the
   *                                    embed
   *
   * @public
   */
  insertEmbed(index, embed, attributes) {
    const y = this.doc;
    if (y !== null) {
      transact(y, (transaction) => {
        const pos = findPosition(transaction, this, index, !attributes);
        insertText(transaction, this, pos, embed, attributes || {});
      });
    } else {
      this._pending.push(() => this.insertEmbed(index, embed, attributes || {}));
    }
  }
  /**
   * Deletes text starting from an index.
   *
   * @param {number} index Index at which to start deleting.
   * @param {number} length The number of characters to remove. Defaults to 1.
   *
   * @public
   */
  delete(index, length2) {
    if (length2 === 0) {
      return;
    }
    const y = this.doc;
    if (y !== null) {
      transact(y, (transaction) => {
        deleteText(transaction, findPosition(transaction, this, index, true), length2);
      });
    } else {
      this._pending.push(() => this.delete(index, length2));
    }
  }
  /**
   * Assigns properties to a range of text.
   *
   * @param {number} index The position where to start formatting.
   * @param {number} length The amount of characters to assign properties to.
   * @param {TextAttributes} attributes Attribute information to apply on the
   *                                    text.
   *
   * @public
   */
  format(index, length2, attributes) {
    if (length2 === 0) {
      return;
    }
    const y = this.doc;
    if (y !== null) {
      transact(y, (transaction) => {
        const pos = findPosition(transaction, this, index, false);
        if (pos.right === null) {
          return;
        }
        formatText(transaction, this, pos, length2, attributes);
      });
    } else {
      this._pending.push(() => this.format(index, length2, attributes));
    }
  }
  /**
   * Removes an attribute.
   *
   * @note Xml-Text nodes don't have attributes. You can use this feature to assign properties to complete text-blocks.
   *
   * @param {String} attributeName The attribute name that is to be removed.
   *
   * @public
   */
  removeAttribute(attributeName) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeMapDelete(transaction, this, attributeName);
      });
    } else {
      this._pending.push(() => this.removeAttribute(attributeName));
    }
  }
  /**
   * Sets or updates an attribute.
   *
   * @note Xml-Text nodes don't have attributes. You can use this feature to assign properties to complete text-blocks.
   *
   * @param {String} attributeName The attribute name that is to be set.
   * @param {any} attributeValue The attribute value that is to be set.
   *
   * @public
   */
  setAttribute(attributeName, attributeValue) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeMapSet(transaction, this, attributeName, attributeValue);
      });
    } else {
      this._pending.push(() => this.setAttribute(attributeName, attributeValue));
    }
  }
  /**
   * Returns an attribute value that belongs to the attribute name.
   *
   * @note Xml-Text nodes don't have attributes. You can use this feature to assign properties to complete text-blocks.
   *
   * @param {String} attributeName The attribute name that identifies the
   *                               queried value.
   * @return {any} The queried attribute value.
   *
   * @public
   */
  getAttribute(attributeName) {
    return (
      /** @type {any} */
      typeMapGet(this, attributeName)
    );
  }
  /**
   * Returns all attribute name/value pairs in a JSON Object.
   *
   * @note Xml-Text nodes don't have attributes. You can use this feature to assign properties to complete text-blocks.
   *
   * @return {Object<string, any>} A JSON Object that describes the attributes.
   *
   * @public
   */
  getAttributes() {
    return typeMapGetAll(this);
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   */
  _write(encoder) {
    encoder.writeTypeRef(YTextRefID);
  }
};
var readYText = (_decoder) => new YText();
var YXmlTreeWalker = class {
  /**
   * @param {YXmlFragment | YXmlElement} root
   * @param {function(AbstractType<any>):boolean} [f]
   */
  constructor(root, f = () => true) {
    this._filter = f;
    this._root = root;
    this._currentNode = /** @type {Item} */
    root._start;
    this._firstCall = true;
    root.doc ?? warnPrematureAccess();
  }
  [Symbol.iterator]() {
    return this;
  }
  /**
   * Get the next node.
   *
   * @return {IteratorResult<YXmlElement|YXmlText|YXmlHook>} The next node.
   *
   * @public
   */
  next() {
    let n = this._currentNode;
    let type = n && n.content && /** @type {any} */
    n.content.type;
    if (n !== null && (!this._firstCall || n.deleted || !this._filter(type))) {
      do {
        type = /** @type {any} */
        n.content.type;
        if (!n.deleted && (type.constructor === YXmlElement || type.constructor === YXmlFragment) && type._start !== null) {
          n = type._start;
        } else {
          while (n !== null) {
            const nxt = n.next;
            if (nxt !== null) {
              n = nxt;
              break;
            } else if (n.parent === this._root) {
              n = null;
            } else {
              n = /** @type {AbstractType<any>} */
              n.parent._item;
            }
          }
        }
      } while (n !== null && (n.deleted || !this._filter(
        /** @type {ContentType} */
        n.content.type
      )));
    }
    this._firstCall = false;
    if (n === null) {
      return { value: void 0, done: true };
    }
    this._currentNode = n;
    return { value: (
      /** @type {any} */
      n.content.type
    ), done: false };
  }
};
var YXmlFragment = class _YXmlFragment extends AbstractType {
  constructor() {
    super();
    this._prelimContent = [];
  }
  /**
   * @type {YXmlElement|YXmlText|null}
   */
  get firstChild() {
    const first = this._first;
    return first ? first.content.getContent()[0] : null;
  }
  /**
   * Integrate this type into the Yjs instance.
   *
   * * Save this struct in the os
   * * This type is sent to other client
   * * Observer functions are fired
   *
   * @param {Doc} y The Yjs instance
   * @param {Item} item
   */
  _integrate(y, item) {
    super._integrate(y, item);
    this.insert(
      0,
      /** @type {Array<any>} */
      this._prelimContent
    );
    this._prelimContent = null;
  }
  _copy() {
    return new _YXmlFragment();
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YXmlFragment}
   */
  clone() {
    const el = new _YXmlFragment();
    el.insert(0, this.toArray().map((item) => item instanceof AbstractType ? item.clone() : item));
    return el;
  }
  get length() {
    this.doc ?? warnPrematureAccess();
    return this._prelimContent === null ? this._length : this._prelimContent.length;
  }
  /**
   * Create a subtree of childNodes.
   *
   * @example
   * const walker = elem.createTreeWalker(dom => dom.nodeName === 'div')
   * for (let node in walker) {
   *   // `node` is a div node
   *   nop(node)
   * }
   *
   * @param {function(AbstractType<any>):boolean} filter Function that is called on each child element and
   *                          returns a Boolean indicating whether the child
   *                          is to be included in the subtree.
   * @return {YXmlTreeWalker} A subtree and a position within it.
   *
   * @public
   */
  createTreeWalker(filter) {
    return new YXmlTreeWalker(this, filter);
  }
  /**
   * Returns the first YXmlElement that matches the query.
   * Similar to DOM's {@link querySelector}.
   *
   * Query support:
   *   - tagname
   * TODO:
   *   - id
   *   - attribute
   *
   * @param {CSS_Selector} query The query on the children.
   * @return {YXmlElement|YXmlText|YXmlHook|null} The first element that matches the query or null.
   *
   * @public
   */
  querySelector(query) {
    query = query.toUpperCase();
    const iterator = new YXmlTreeWalker(this, (element) => element.nodeName && element.nodeName.toUpperCase() === query);
    const next = iterator.next();
    if (next.done) {
      return null;
    } else {
      return next.value;
    }
  }
  /**
   * Returns all YXmlElements that match the query.
   * Similar to Dom's {@link querySelectorAll}.
   *
   * @todo Does not yet support all queries. Currently only query by tagName.
   *
   * @param {CSS_Selector} query The query on the children
   * @return {Array<YXmlElement|YXmlText|YXmlHook|null>} The elements that match this query.
   *
   * @public
   */
  querySelectorAll(query) {
    query = query.toUpperCase();
    return from(new YXmlTreeWalker(this, (element) => element.nodeName && element.nodeName.toUpperCase() === query));
  }
  /**
   * Creates YXmlEvent and calls observers.
   *
   * @param {Transaction} transaction
   * @param {Set<null|string>} parentSubs Keys changed on this type. `null` if list was modified.
   */
  _callObserver(transaction, parentSubs) {
    callTypeObservers(this, transaction, new YXmlEvent(this, parentSubs, transaction));
  }
  /**
   * Get the string representation of all the children of this YXmlFragment.
   *
   * @return {string} The string representation of all children.
   */
  toString() {
    return typeListMap(this, (xml) => xml.toString()).join("");
  }
  /**
   * @return {string}
   */
  toJSON() {
    return this.toString();
  }
  /**
   * Creates a Dom Element that mirrors this YXmlElement.
   *
   * @param {Document} [_document=document] The document object (you must define
   *                                        this when calling this method in
   *                                        nodejs)
   * @param {Object<string, any>} [hooks={}] Optional property to customize how hooks
   *                                             are presented in the DOM
   * @param {any} [binding] You should not set this property. This is
   *                               used if DomBinding wants to create a
   *                               association to the created DOM type.
   * @return {Node} The {@link https://developer.mozilla.org/en-US/docs/Web/API/Element|Dom Element}
   *
   * @public
   */
  toDOM(_document = document, hooks = {}, binding) {
    const fragment = _document.createDocumentFragment();
    if (binding !== void 0) {
      binding._createAssociation(fragment, this);
    }
    typeListForEach(this, (xmlType) => {
      fragment.insertBefore(xmlType.toDOM(_document, hooks, binding), null);
    });
    return fragment;
  }
  /**
   * Inserts new content at an index.
   *
   * @example
   *  // Insert character 'a' at position 0
   *  xml.insert(0, [new Y.XmlText('text')])
   *
   * @param {number} index The index to insert content at
   * @param {Array<YXmlElement|YXmlText>} content The array of content
   */
  insert(index, content) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeListInsertGenerics(transaction, this, index, content);
      });
    } else {
      this._prelimContent.splice(index, 0, ...content);
    }
  }
  /**
   * Inserts new content at an index.
   *
   * @example
   *  // Insert character 'a' at position 0
   *  xml.insert(0, [new Y.XmlText('text')])
   *
   * @param {null|Item|YXmlElement|YXmlText} ref The index to insert content at
   * @param {Array<YXmlElement|YXmlText>} content The array of content
   */
  insertAfter(ref, content) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        const refItem = ref && ref instanceof AbstractType ? ref._item : ref;
        typeListInsertGenericsAfter(transaction, this, refItem, content);
      });
    } else {
      const pc = (
        /** @type {Array<any>} */
        this._prelimContent
      );
      const index = ref === null ? 0 : pc.findIndex((el) => el === ref) + 1;
      if (index === 0 && ref !== null) {
        throw create3("Reference item not found");
      }
      pc.splice(index, 0, ...content);
    }
  }
  /**
   * Deletes elements starting from an index.
   *
   * @param {number} index Index at which to start deleting elements
   * @param {number} [length=1] The number of elements to remove. Defaults to 1.
   */
  delete(index, length2 = 1) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeListDelete(transaction, this, index, length2);
      });
    } else {
      this._prelimContent.splice(index, length2);
    }
  }
  /**
   * Transforms this YArray to a JavaScript Array.
   *
   * @return {Array<YXmlElement|YXmlText|YXmlHook>}
   */
  toArray() {
    return typeListToArray(this);
  }
  /**
   * Appends content to this YArray.
   *
   * @param {Array<YXmlElement|YXmlText>} content Array of content to append.
   */
  push(content) {
    this.insert(this.length, content);
  }
  /**
   * Prepends content to this YArray.
   *
   * @param {Array<YXmlElement|YXmlText>} content Array of content to prepend.
   */
  unshift(content) {
    this.insert(0, content);
  }
  /**
   * Returns the i-th element from a YArray.
   *
   * @param {number} index The index of the element to return from the YArray
   * @return {YXmlElement|YXmlText}
   */
  get(index) {
    return typeListGet(this, index);
  }
  /**
   * Returns a portion of this YXmlFragment into a JavaScript Array selected
   * from start to end (end not included).
   *
   * @param {number} [start]
   * @param {number} [end]
   * @return {Array<YXmlElement|YXmlText>}
   */
  slice(start = 0, end = this.length) {
    return typeListSlice(this, start, end);
  }
  /**
   * Executes a provided function on once on every child element.
   *
   * @param {function(YXmlElement|YXmlText,number, typeof self):void} f A function to execute on every element of this YArray.
   */
  forEach(f) {
    typeListForEach(this, f);
  }
  /**
   * Transform the properties of this type to binary and write it to an
   * BinaryEncoder.
   *
   * This is called when this Item is sent to a remote peer.
   *
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder The encoder to write data to.
   */
  _write(encoder) {
    encoder.writeTypeRef(YXmlFragmentRefID);
  }
};
var readYXmlFragment = (_decoder) => new YXmlFragment();
var YXmlElement = class _YXmlElement extends YXmlFragment {
  constructor(nodeName = "UNDEFINED") {
    super();
    this.nodeName = nodeName;
    this._prelimAttrs = /* @__PURE__ */ new Map();
  }
  /**
   * @type {YXmlElement|YXmlText|null}
   */
  get nextSibling() {
    const n = this._item ? this._item.next : null;
    return n ? (
      /** @type {YXmlElement|YXmlText} */
      /** @type {ContentType} */
      n.content.type
    ) : null;
  }
  /**
   * @type {YXmlElement|YXmlText|null}
   */
  get prevSibling() {
    const n = this._item ? this._item.prev : null;
    return n ? (
      /** @type {YXmlElement|YXmlText} */
      /** @type {ContentType} */
      n.content.type
    ) : null;
  }
  /**
   * Integrate this type into the Yjs instance.
   *
   * * Save this struct in the os
   * * This type is sent to other client
   * * Observer functions are fired
   *
   * @param {Doc} y The Yjs instance
   * @param {Item} item
   */
  _integrate(y, item) {
    super._integrate(y, item);
    /** @type {Map<string, any>} */
    this._prelimAttrs.forEach((value, key2) => {
      this.setAttribute(key2, value);
    });
    this._prelimAttrs = null;
  }
  /**
   * Creates an Item with the same effect as this Item (without position effect)
   *
   * @return {YXmlElement}
   */
  _copy() {
    return new _YXmlElement(this.nodeName);
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YXmlElement<KV>}
   */
  clone() {
    const el = new _YXmlElement(this.nodeName);
    const attrs = this.getAttributes();
    forEach(attrs, (value, key2) => {
      el.setAttribute(
        key2,
        /** @type {any} */
        value
      );
    });
    el.insert(0, this.toArray().map((v) => v instanceof AbstractType ? v.clone() : v));
    return el;
  }
  /**
   * Returns the XML serialization of this YXmlElement.
   * The attributes are ordered by attribute-name, so you can easily use this
   * method to compare YXmlElements
   *
   * @return {string} The string representation of this type.
   *
   * @public
   */
  toString() {
    const attrs = this.getAttributes();
    const stringBuilder = [];
    const keys2 = [];
    for (const key2 in attrs) {
      keys2.push(key2);
    }
    keys2.sort();
    const keysLen = keys2.length;
    for (let i = 0; i < keysLen; i++) {
      const key2 = keys2[i];
      stringBuilder.push(key2 + '="' + attrs[key2] + '"');
    }
    const nodeName = this.nodeName.toLocaleLowerCase();
    const attrsString = stringBuilder.length > 0 ? " " + stringBuilder.join(" ") : "";
    return `<${nodeName}${attrsString}>${super.toString()}</${nodeName}>`;
  }
  /**
   * Removes an attribute from this YXmlElement.
   *
   * @param {string} attributeName The attribute name that is to be removed.
   *
   * @public
   */
  removeAttribute(attributeName) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeMapDelete(transaction, this, attributeName);
      });
    } else {
      this._prelimAttrs.delete(attributeName);
    }
  }
  /**
   * Sets or updates an attribute.
   *
   * @template {keyof KV & string} KEY
   *
   * @param {KEY} attributeName The attribute name that is to be set.
   * @param {KV[KEY]} attributeValue The attribute value that is to be set.
   *
   * @public
   */
  setAttribute(attributeName, attributeValue) {
    if (this.doc !== null) {
      transact(this.doc, (transaction) => {
        typeMapSet(transaction, this, attributeName, attributeValue);
      });
    } else {
      this._prelimAttrs.set(attributeName, attributeValue);
    }
  }
  /**
   * Returns an attribute value that belongs to the attribute name.
   *
   * @template {keyof KV & string} KEY
   *
   * @param {KEY} attributeName The attribute name that identifies the
   *                               queried value.
   * @return {KV[KEY]|undefined} The queried attribute value.
   *
   * @public
   */
  getAttribute(attributeName) {
    return (
      /** @type {any} */
      typeMapGet(this, attributeName)
    );
  }
  /**
   * Returns whether an attribute exists
   *
   * @param {string} attributeName The attribute name to check for existence.
   * @return {boolean} whether the attribute exists.
   *
   * @public
   */
  hasAttribute(attributeName) {
    return (
      /** @type {any} */
      typeMapHas(this, attributeName)
    );
  }
  /**
   * Returns all attribute name/value pairs in a JSON Object.
   *
   * @param {Snapshot} [snapshot]
   * @return {{ [Key in Extract<keyof KV,string>]?: KV[Key]}} A JSON Object that describes the attributes.
   *
   * @public
   */
  getAttributes(snapshot) {
    return (
      /** @type {any} */
      snapshot ? typeMapGetAllSnapshot(this, snapshot) : typeMapGetAll(this)
    );
  }
  /**
   * Creates a Dom Element that mirrors this YXmlElement.
   *
   * @param {Document} [_document=document] The document object (you must define
   *                                        this when calling this method in
   *                                        nodejs)
   * @param {Object<string, any>} [hooks={}] Optional property to customize how hooks
   *                                             are presented in the DOM
   * @param {any} [binding] You should not set this property. This is
   *                               used if DomBinding wants to create a
   *                               association to the created DOM type.
   * @return {Node} The {@link https://developer.mozilla.org/en-US/docs/Web/API/Element|Dom Element}
   *
   * @public
   */
  toDOM(_document = document, hooks = {}, binding) {
    const dom = _document.createElement(this.nodeName);
    const attrs = this.getAttributes();
    for (const key2 in attrs) {
      const value = attrs[key2];
      if (typeof value === "string") {
        dom.setAttribute(key2, value);
      }
    }
    typeListForEach(this, (yxml) => {
      dom.appendChild(yxml.toDOM(_document, hooks, binding));
    });
    if (binding !== void 0) {
      binding._createAssociation(dom, this);
    }
    return dom;
  }
  /**
   * Transform the properties of this type to binary and write it to an
   * BinaryEncoder.
   *
   * This is called when this Item is sent to a remote peer.
   *
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder The encoder to write data to.
   */
  _write(encoder) {
    encoder.writeTypeRef(YXmlElementRefID);
    encoder.writeKey(this.nodeName);
  }
};
var readYXmlElement = (decoder) => new YXmlElement(decoder.readKey());
var YXmlEvent = class extends YEvent {
  /**
   * @param {YXmlElement|YXmlText|YXmlFragment} target The target on which the event is created.
   * @param {Set<string|null>} subs The set of changed attributes. `null` is included if the
   *                   child list changed.
   * @param {Transaction} transaction The transaction instance with which the
   *                                  change was created.
   */
  constructor(target, subs, transaction) {
    super(target, transaction);
    this.childListChanged = false;
    this.attributesChanged = /* @__PURE__ */ new Set();
    subs.forEach((sub) => {
      if (sub === null) {
        this.childListChanged = true;
      } else {
        this.attributesChanged.add(sub);
      }
    });
  }
};
var YXmlHook = class _YXmlHook extends YMap {
  /**
   * @param {string} hookName nodeName of the Dom Node.
   */
  constructor(hookName) {
    super();
    this.hookName = hookName;
  }
  /**
   * Creates an Item with the same effect as this Item (without position effect)
   */
  _copy() {
    return new _YXmlHook(this.hookName);
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YXmlHook}
   */
  clone() {
    const el = new _YXmlHook(this.hookName);
    this.forEach((value, key2) => {
      el.set(key2, value);
    });
    return el;
  }
  /**
   * Creates a Dom Element that mirrors this YXmlElement.
   *
   * @param {Document} [_document=document] The document object (you must define
   *                                        this when calling this method in
   *                                        nodejs)
   * @param {Object.<string, any>} [hooks] Optional property to customize how hooks
   *                                             are presented in the DOM
   * @param {any} [binding] You should not set this property. This is
   *                               used if DomBinding wants to create a
   *                               association to the created DOM type
   * @return {Element} The {@link https://developer.mozilla.org/en-US/docs/Web/API/Element|Dom Element}
   *
   * @public
   */
  toDOM(_document = document, hooks = {}, binding) {
    const hook = hooks[this.hookName];
    let dom;
    if (hook !== void 0) {
      dom = hook.createDom(this);
    } else {
      dom = document.createElement(this.hookName);
    }
    dom.setAttribute("data-yjs-hook", this.hookName);
    if (binding !== void 0) {
      binding._createAssociation(dom, this);
    }
    return dom;
  }
  /**
   * Transform the properties of this type to binary and write it to an
   * BinaryEncoder.
   *
   * This is called when this Item is sent to a remote peer.
   *
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder The encoder to write data to.
   */
  _write(encoder) {
    encoder.writeTypeRef(YXmlHookRefID);
    encoder.writeKey(this.hookName);
  }
};
var readYXmlHook = (decoder) => new YXmlHook(decoder.readKey());
var YXmlText = class _YXmlText extends YText {
  /**
   * @type {YXmlElement|YXmlText|null}
   */
  get nextSibling() {
    const n = this._item ? this._item.next : null;
    return n ? (
      /** @type {YXmlElement|YXmlText} */
      /** @type {ContentType} */
      n.content.type
    ) : null;
  }
  /**
   * @type {YXmlElement|YXmlText|null}
   */
  get prevSibling() {
    const n = this._item ? this._item.prev : null;
    return n ? (
      /** @type {YXmlElement|YXmlText} */
      /** @type {ContentType} */
      n.content.type
    ) : null;
  }
  _copy() {
    return new _YXmlText();
  }
  /**
   * Makes a copy of this data type that can be included somewhere else.
   *
   * Note that the content is only readable _after_ it has been included somewhere in the Ydoc.
   *
   * @return {YXmlText}
   */
  clone() {
    const text = new _YXmlText();
    text.applyDelta(this.toDelta());
    return text;
  }
  /**
   * Creates a Dom Element that mirrors this YXmlText.
   *
   * @param {Document} [_document=document] The document object (you must define
   *                                        this when calling this method in
   *                                        nodejs)
   * @param {Object<string, any>} [hooks] Optional property to customize how hooks
   *                                             are presented in the DOM
   * @param {any} [binding] You should not set this property. This is
   *                               used if DomBinding wants to create a
   *                               association to the created DOM type.
   * @return {Text} The {@link https://developer.mozilla.org/en-US/docs/Web/API/Element|Dom Element}
   *
   * @public
   */
  toDOM(_document = document, hooks, binding) {
    const dom = _document.createTextNode(this.toString());
    if (binding !== void 0) {
      binding._createAssociation(dom, this);
    }
    return dom;
  }
  toString() {
    return this.toDelta().map((delta) => {
      const nestedNodes = [];
      for (const nodeName in delta.attributes) {
        const attrs = [];
        for (const key2 in delta.attributes[nodeName]) {
          attrs.push({ key: key2, value: delta.attributes[nodeName][key2] });
        }
        attrs.sort((a, b) => a.key < b.key ? -1 : 1);
        nestedNodes.push({ nodeName, attrs });
      }
      nestedNodes.sort((a, b) => a.nodeName < b.nodeName ? -1 : 1);
      let str2 = "";
      for (let i = 0; i < nestedNodes.length; i++) {
        const node = nestedNodes[i];
        str2 += `<${node.nodeName}`;
        for (let j = 0; j < node.attrs.length; j++) {
          const attr = node.attrs[j];
          str2 += ` ${attr.key}="${attr.value}"`;
        }
        str2 += ">";
      }
      str2 += delta.insert;
      for (let i = nestedNodes.length - 1; i >= 0; i--) {
        str2 += `</${nestedNodes[i].nodeName}>`;
      }
      return str2;
    }).join("");
  }
  /**
   * @return {string}
   */
  toJSON() {
    return this.toString();
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   */
  _write(encoder) {
    encoder.writeTypeRef(YXmlTextRefID);
  }
};
var readYXmlText = (decoder) => new YXmlText();
var AbstractStruct = class {
  /**
   * @param {ID} id
   * @param {number} length
   */
  constructor(id2, length2) {
    this.id = id2;
    this.length = length2;
  }
  /**
   * @type {boolean}
   */
  get deleted() {
    throw methodUnimplemented();
  }
  /**
   * Merge this struct with the item to the right.
   * This method is already assuming that `this.id.clock + this.length === this.id.clock`.
   * Also this method does *not* remove right from StructStore!
   * @param {AbstractStruct} right
   * @return {boolean} whether this merged with right
   */
  mergeWith(right) {
    return false;
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder The encoder to write data to.
   * @param {number} offset
   * @param {number} encodingRef
   */
  write(encoder, offset, encodingRef) {
    throw methodUnimplemented();
  }
  /**
   * @param {Transaction} transaction
   * @param {number} offset
   */
  integrate(transaction, offset) {
    throw methodUnimplemented();
  }
};
var structGCRefNumber = 0;
var GC = class extends AbstractStruct {
  get deleted() {
    return true;
  }
  delete() {
  }
  /**
   * @param {GC} right
   * @return {boolean}
   */
  mergeWith(right) {
    if (this.constructor !== right.constructor) {
      return false;
    }
    this.length += right.length;
    return true;
  }
  /**
   * @param {Transaction} transaction
   * @param {number} offset
   */
  integrate(transaction, offset) {
    if (offset > 0) {
      this.id.clock += offset;
      this.length -= offset;
    }
    addStruct(transaction.doc.store, this);
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeInfo(structGCRefNumber);
    encoder.writeLen(this.length - offset);
  }
  /**
   * @param {Transaction} transaction
   * @param {StructStore} store
   * @return {null | number}
   */
  getMissing(transaction, store) {
    return null;
  }
};
var ContentBinary = class _ContentBinary {
  /**
   * @param {Uint8Array} content
   */
  constructor(content) {
    this.content = content;
  }
  /**
   * @return {number}
   */
  getLength() {
    return 1;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return [this.content];
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentBinary}
   */
  copy() {
    return new _ContentBinary(this.content);
  }
  /**
   * @param {number} offset
   * @return {ContentBinary}
   */
  splice(offset) {
    throw methodUnimplemented();
  }
  /**
   * @param {ContentBinary} right
   * @return {boolean}
   */
  mergeWith(right) {
    return false;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeBuf(this.content);
  }
  /**
   * @return {number}
   */
  getRef() {
    return 3;
  }
};
var readContentBinary = (decoder) => new ContentBinary(decoder.readBuf());
var ContentDeleted = class _ContentDeleted {
  /**
   * @param {number} len
   */
  constructor(len) {
    this.len = len;
  }
  /**
   * @return {number}
   */
  getLength() {
    return this.len;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return [];
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return false;
  }
  /**
   * @return {ContentDeleted}
   */
  copy() {
    return new _ContentDeleted(this.len);
  }
  /**
   * @param {number} offset
   * @return {ContentDeleted}
   */
  splice(offset) {
    const right = new _ContentDeleted(this.len - offset);
    this.len = offset;
    return right;
  }
  /**
   * @param {ContentDeleted} right
   * @return {boolean}
   */
  mergeWith(right) {
    this.len += right.len;
    return true;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
    addToDeleteSet(transaction.deleteSet, item.id.client, item.id.clock, this.len);
    item.markDeleted();
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeLen(this.len - offset);
  }
  /**
   * @return {number}
   */
  getRef() {
    return 1;
  }
};
var readContentDeleted = (decoder) => new ContentDeleted(decoder.readLen());
var createDocFromOpts = (guid, opts) => new Doc({ guid, ...opts, shouldLoad: opts.shouldLoad || opts.autoLoad || false });
var ContentDoc = class _ContentDoc {
  /**
   * @param {Doc} doc
   */
  constructor(doc) {
    if (doc._item) {
      console.error("This document was already integrated as a sub-document. You should create a second instance instead with the same guid.");
    }
    this.doc = doc;
    const opts = {};
    this.opts = opts;
    if (!doc.gc) {
      opts.gc = false;
    }
    if (doc.autoLoad) {
      opts.autoLoad = true;
    }
    if (doc.meta !== null) {
      opts.meta = doc.meta;
    }
  }
  /**
   * @return {number}
   */
  getLength() {
    return 1;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return [this.doc];
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentDoc}
   */
  copy() {
    return new _ContentDoc(createDocFromOpts(this.doc.guid, this.opts));
  }
  /**
   * @param {number} offset
   * @return {ContentDoc}
   */
  splice(offset) {
    throw methodUnimplemented();
  }
  /**
   * @param {ContentDoc} right
   * @return {boolean}
   */
  mergeWith(right) {
    return false;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
    this.doc._item = item;
    transaction.subdocsAdded.add(this.doc);
    if (this.doc.shouldLoad) {
      transaction.subdocsLoaded.add(this.doc);
    }
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
    if (transaction.subdocsAdded.has(this.doc)) {
      transaction.subdocsAdded.delete(this.doc);
    } else {
      transaction.subdocsRemoved.add(this.doc);
    }
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeString(this.doc.guid);
    encoder.writeAny(this.opts);
  }
  /**
   * @return {number}
   */
  getRef() {
    return 9;
  }
};
var readContentDoc = (decoder) => new ContentDoc(createDocFromOpts(decoder.readString(), decoder.readAny()));
var ContentEmbed = class _ContentEmbed {
  /**
   * @param {Object} embed
   */
  constructor(embed) {
    this.embed = embed;
  }
  /**
   * @return {number}
   */
  getLength() {
    return 1;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return [this.embed];
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentEmbed}
   */
  copy() {
    return new _ContentEmbed(this.embed);
  }
  /**
   * @param {number} offset
   * @return {ContentEmbed}
   */
  splice(offset) {
    throw methodUnimplemented();
  }
  /**
   * @param {ContentEmbed} right
   * @return {boolean}
   */
  mergeWith(right) {
    return false;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeJSON(this.embed);
  }
  /**
   * @return {number}
   */
  getRef() {
    return 5;
  }
};
var readContentEmbed = (decoder) => new ContentEmbed(decoder.readJSON());
var ContentFormat = class _ContentFormat {
  /**
   * @param {string} key
   * @param {Object} value
   */
  constructor(key2, value) {
    this.key = key2;
    this.value = value;
  }
  /**
   * @return {number}
   */
  getLength() {
    return 1;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return [];
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return false;
  }
  /**
   * @return {ContentFormat}
   */
  copy() {
    return new _ContentFormat(this.key, this.value);
  }
  /**
   * @param {number} _offset
   * @return {ContentFormat}
   */
  splice(_offset) {
    throw methodUnimplemented();
  }
  /**
   * @param {ContentFormat} _right
   * @return {boolean}
   */
  mergeWith(_right) {
    return false;
  }
  /**
   * @param {Transaction} _transaction
   * @param {Item} item
   */
  integrate(_transaction, item) {
    const p = (
      /** @type {YText} */
      item.parent
    );
    p._searchMarker = null;
    p._hasFormatting = true;
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeKey(this.key);
    encoder.writeJSON(this.value);
  }
  /**
   * @return {number}
   */
  getRef() {
    return 6;
  }
};
var readContentFormat = (decoder) => new ContentFormat(decoder.readKey(), decoder.readJSON());
var ContentJSON = class _ContentJSON {
  /**
   * @param {Array<any>} arr
   */
  constructor(arr) {
    this.arr = arr;
  }
  /**
   * @return {number}
   */
  getLength() {
    return this.arr.length;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return this.arr;
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentJSON}
   */
  copy() {
    return new _ContentJSON(this.arr);
  }
  /**
   * @param {number} offset
   * @return {ContentJSON}
   */
  splice(offset) {
    const right = new _ContentJSON(this.arr.slice(offset));
    this.arr = this.arr.slice(0, offset);
    return right;
  }
  /**
   * @param {ContentJSON} right
   * @return {boolean}
   */
  mergeWith(right) {
    this.arr = this.arr.concat(right.arr);
    return true;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    const len = this.arr.length;
    encoder.writeLen(len - offset);
    for (let i = offset; i < len; i++) {
      const c = this.arr[i];
      encoder.writeString(c === void 0 ? "undefined" : JSON.stringify(c));
    }
  }
  /**
   * @return {number}
   */
  getRef() {
    return 2;
  }
};
var readContentJSON = (decoder) => {
  const len = decoder.readLen();
  const cs = [];
  for (let i = 0; i < len; i++) {
    const c = decoder.readString();
    if (c === "undefined") {
      cs.push(void 0);
    } else {
      cs.push(JSON.parse(c));
    }
  }
  return new ContentJSON(cs);
};
var isDevMode = getVariable("node_env") === "development";
var ContentAny = class _ContentAny {
  /**
   * @param {Array<any>} arr
   */
  constructor(arr) {
    this.arr = arr;
    isDevMode && deepFreeze(arr);
  }
  /**
   * @return {number}
   */
  getLength() {
    return this.arr.length;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return this.arr;
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentAny}
   */
  copy() {
    return new _ContentAny(this.arr);
  }
  /**
   * @param {number} offset
   * @return {ContentAny}
   */
  splice(offset) {
    const right = new _ContentAny(this.arr.slice(offset));
    this.arr = this.arr.slice(0, offset);
    return right;
  }
  /**
   * @param {ContentAny} right
   * @return {boolean}
   */
  mergeWith(right) {
    this.arr = this.arr.concat(right.arr);
    return true;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    const len = this.arr.length;
    encoder.writeLen(len - offset);
    for (let i = offset; i < len; i++) {
      const c = this.arr[i];
      encoder.writeAny(c);
    }
  }
  /**
   * @return {number}
   */
  getRef() {
    return 8;
  }
};
var readContentAny = (decoder) => {
  const len = decoder.readLen();
  const cs = [];
  for (let i = 0; i < len; i++) {
    cs.push(decoder.readAny());
  }
  return new ContentAny(cs);
};
var ContentString = class _ContentString {
  /**
   * @param {string} str
   */
  constructor(str2) {
    this.str = str2;
  }
  /**
   * @return {number}
   */
  getLength() {
    return this.str.length;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return this.str.split("");
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentString}
   */
  copy() {
    return new _ContentString(this.str);
  }
  /**
   * @param {number} offset
   * @return {ContentString}
   */
  splice(offset) {
    const right = new _ContentString(this.str.slice(offset));
    this.str = this.str.slice(0, offset);
    const firstCharCode = this.str.charCodeAt(offset - 1);
    if (firstCharCode >= 55296 && firstCharCode <= 56319) {
      this.str = this.str.slice(0, offset - 1) + "\uFFFD";
      right.str = "\uFFFD" + right.str.slice(1);
    }
    return right;
  }
  /**
   * @param {ContentString} right
   * @return {boolean}
   */
  mergeWith(right) {
    this.str += right.str;
    return true;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeString(offset === 0 ? this.str : this.str.slice(offset));
  }
  /**
   * @return {number}
   */
  getRef() {
    return 4;
  }
};
var readContentString = (decoder) => new ContentString(decoder.readString());
var typeRefs = [
  readYArray,
  readYMap,
  readYText,
  readYXmlElement,
  readYXmlFragment,
  readYXmlHook,
  readYXmlText
];
var YArrayRefID = 0;
var YMapRefID = 1;
var YTextRefID = 2;
var YXmlElementRefID = 3;
var YXmlFragmentRefID = 4;
var YXmlHookRefID = 5;
var YXmlTextRefID = 6;
var ContentType = class _ContentType {
  /**
   * @param {AbstractType<any>} type
   */
  constructor(type) {
    this.type = type;
  }
  /**
   * @return {number}
   */
  getLength() {
    return 1;
  }
  /**
   * @return {Array<any>}
   */
  getContent() {
    return [this.type];
  }
  /**
   * @return {boolean}
   */
  isCountable() {
    return true;
  }
  /**
   * @return {ContentType}
   */
  copy() {
    return new _ContentType(this.type._copy());
  }
  /**
   * @param {number} offset
   * @return {ContentType}
   */
  splice(offset) {
    throw methodUnimplemented();
  }
  /**
   * @param {ContentType} right
   * @return {boolean}
   */
  mergeWith(right) {
    return false;
  }
  /**
   * @param {Transaction} transaction
   * @param {Item} item
   */
  integrate(transaction, item) {
    this.type._integrate(transaction.doc, item);
  }
  /**
   * @param {Transaction} transaction
   */
  delete(transaction) {
    let item = this.type._start;
    while (item !== null) {
      if (!item.deleted) {
        item.delete(transaction);
      } else if (item.id.clock < (transaction.beforeState.get(item.id.client) || 0)) {
        transaction._mergeStructs.push(item);
      }
      item = item.right;
    }
    this.type._map.forEach((item2) => {
      if (!item2.deleted) {
        item2.delete(transaction);
      } else if (item2.id.clock < (transaction.beforeState.get(item2.id.client) || 0)) {
        transaction._mergeStructs.push(item2);
      }
    });
    transaction.changed.delete(this.type);
  }
  /**
   * @param {StructStore} store
   */
  gc(store) {
    let item = this.type._start;
    while (item !== null) {
      item.gc(store, true);
      item = item.right;
    }
    this.type._start = null;
    this.type._map.forEach(
      /** @param {Item | null} item */
      (item2) => {
        while (item2 !== null) {
          item2.gc(store, true);
          item2 = item2.left;
        }
      }
    );
    this.type._map = /* @__PURE__ */ new Map();
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    this.type._write(encoder);
  }
  /**
   * @return {number}
   */
  getRef() {
    return 7;
  }
};
var readContentType = (decoder) => new ContentType(typeRefs[decoder.readTypeRef()](decoder));
var followRedone = (store, id2) => {
  let nextID = id2;
  let diff = 0;
  let item;
  do {
    if (diff > 0) {
      nextID = createID(nextID.client, nextID.clock + diff);
    }
    item = getItem(store, nextID);
    diff = nextID.clock - item.id.clock;
    nextID = item.redone;
  } while (nextID !== null && item instanceof Item);
  return {
    item,
    diff
  };
};
var splitItem = (transaction, leftItem, diff) => {
  const { client, clock } = leftItem.id;
  const rightItem = new Item(
    createID(client, clock + diff),
    leftItem,
    createID(client, clock + diff - 1),
    leftItem.right,
    leftItem.rightOrigin,
    leftItem.parent,
    leftItem.parentSub,
    leftItem.content.splice(diff)
  );
  if (leftItem.deleted) {
    rightItem.markDeleted();
  }
  if (leftItem.keep) {
    rightItem.keep = true;
  }
  if (leftItem.redone !== null) {
    rightItem.redone = createID(leftItem.redone.client, leftItem.redone.clock + diff);
  }
  leftItem.right = rightItem;
  if (rightItem.right !== null) {
    rightItem.right.left = rightItem;
  }
  transaction._mergeStructs.push(rightItem);
  if (rightItem.parentSub !== null && rightItem.right === null) {
    rightItem.parent._map.set(rightItem.parentSub, rightItem);
  }
  leftItem.length = diff;
  return rightItem;
};
var Item = class _Item extends AbstractStruct {
  /**
   * @param {ID} id
   * @param {Item | null} left
   * @param {ID | null} origin
   * @param {Item | null} right
   * @param {ID | null} rightOrigin
   * @param {AbstractType<any>|ID|null} parent Is a type if integrated, is null if it is possible to copy parent from left or right, is ID before integration to search for it.
   * @param {string | null} parentSub
   * @param {AbstractContent} content
   */
  constructor(id2, left, origin, right, rightOrigin, parent, parentSub, content) {
    super(id2, content.getLength());
    this.origin = origin;
    this.left = left;
    this.right = right;
    this.rightOrigin = rightOrigin;
    this.parent = parent;
    this.parentSub = parentSub;
    this.redone = null;
    this.content = content;
    this.info = this.content.isCountable() ? BIT2 : 0;
  }
  /**
   * This is used to mark the item as an indexed fast-search marker
   *
   * @type {boolean}
   */
  set marker(isMarked) {
    if ((this.info & BIT4) > 0 !== isMarked) {
      this.info ^= BIT4;
    }
  }
  get marker() {
    return (this.info & BIT4) > 0;
  }
  /**
   * If true, do not garbage collect this Item.
   */
  get keep() {
    return (this.info & BIT1) > 0;
  }
  set keep(doKeep) {
    if (this.keep !== doKeep) {
      this.info ^= BIT1;
    }
  }
  get countable() {
    return (this.info & BIT2) > 0;
  }
  /**
   * Whether this item was deleted or not.
   * @type {Boolean}
   */
  get deleted() {
    return (this.info & BIT3) > 0;
  }
  set deleted(doDelete) {
    if (this.deleted !== doDelete) {
      this.info ^= BIT3;
    }
  }
  markDeleted() {
    this.info |= BIT3;
  }
  /**
   * Return the creator clientID of the missing op or define missing items and return null.
   *
   * @param {Transaction} transaction
   * @param {StructStore} store
   * @return {null | number}
   */
  getMissing(transaction, store) {
    if (this.origin && this.origin.client !== this.id.client && this.origin.clock >= getState(store, this.origin.client)) {
      return this.origin.client;
    }
    if (this.rightOrigin && this.rightOrigin.client !== this.id.client && this.rightOrigin.clock >= getState(store, this.rightOrigin.client)) {
      return this.rightOrigin.client;
    }
    if (this.parent && this.parent.constructor === ID && this.id.client !== this.parent.client && this.parent.clock >= getState(store, this.parent.client)) {
      return this.parent.client;
    }
    if (this.origin) {
      this.left = getItemCleanEnd(transaction, store, this.origin);
      this.origin = this.left.lastId;
    }
    if (this.rightOrigin) {
      this.right = getItemCleanStart(transaction, this.rightOrigin);
      this.rightOrigin = this.right.id;
    }
    if (this.left && this.left.constructor === GC || this.right && this.right.constructor === GC) {
      this.parent = null;
    } else if (!this.parent) {
      if (this.left && this.left.constructor === _Item) {
        this.parent = this.left.parent;
        this.parentSub = this.left.parentSub;
      } else if (this.right && this.right.constructor === _Item) {
        this.parent = this.right.parent;
        this.parentSub = this.right.parentSub;
      }
    } else if (this.parent.constructor === ID) {
      const parentItem = getItem(store, this.parent);
      if (parentItem.constructor === GC) {
        this.parent = null;
      } else {
        this.parent = /** @type {ContentType} */
        parentItem.content.type;
      }
    }
    return null;
  }
  /**
   * @param {Transaction} transaction
   * @param {number} offset
   */
  integrate(transaction, offset) {
    if (offset > 0) {
      this.id.clock += offset;
      this.left = getItemCleanEnd(transaction, transaction.doc.store, createID(this.id.client, this.id.clock - 1));
      this.origin = this.left.lastId;
      this.content = this.content.splice(offset);
      this.length -= offset;
    }
    if (this.parent) {
      if (!this.left && (!this.right || this.right.left !== null) || this.left && this.left.right !== this.right) {
        let left = this.left;
        let o;
        if (left !== null) {
          o = left.right;
        } else if (this.parentSub !== null) {
          o = /** @type {AbstractType<any>} */
          this.parent._map.get(this.parentSub) || null;
          while (o !== null && o.left !== null) {
            o = o.left;
          }
        } else {
          o = /** @type {AbstractType<any>} */
          this.parent._start;
        }
        const conflictingItems = /* @__PURE__ */ new Set();
        const itemsBeforeOrigin = /* @__PURE__ */ new Set();
        while (o !== null && o !== this.right) {
          itemsBeforeOrigin.add(o);
          conflictingItems.add(o);
          if (compareIDs(this.origin, o.origin)) {
            if (o.id.client < this.id.client) {
              left = o;
              conflictingItems.clear();
            } else if (compareIDs(this.rightOrigin, o.rightOrigin)) {
              break;
            }
          } else if (o.origin !== null && itemsBeforeOrigin.has(getItem(transaction.doc.store, o.origin))) {
            if (!conflictingItems.has(getItem(transaction.doc.store, o.origin))) {
              left = o;
              conflictingItems.clear();
            }
          } else {
            break;
          }
          o = o.right;
        }
        this.left = left;
      }
      if (this.left !== null) {
        const right = this.left.right;
        this.right = right;
        this.left.right = this;
      } else {
        let r;
        if (this.parentSub !== null) {
          r = /** @type {AbstractType<any>} */
          this.parent._map.get(this.parentSub) || null;
          while (r !== null && r.left !== null) {
            r = r.left;
          }
        } else {
          r = /** @type {AbstractType<any>} */
          this.parent._start;
          this.parent._start = this;
        }
        this.right = r;
      }
      if (this.right !== null) {
        this.right.left = this;
      } else if (this.parentSub !== null) {
        this.parent._map.set(this.parentSub, this);
        if (this.left !== null) {
          this.left.delete(transaction);
        }
      }
      if (this.parentSub === null && this.countable && !this.deleted) {
        this.parent._length += this.length;
      }
      addStruct(transaction.doc.store, this);
      this.content.integrate(transaction, this);
      addChangedTypeToTransaction(
        transaction,
        /** @type {AbstractType<any>} */
        this.parent,
        this.parentSub
      );
      if (
        /** @type {AbstractType<any>} */
        this.parent._item !== null && /** @type {AbstractType<any>} */
        this.parent._item.deleted || this.parentSub !== null && this.right !== null
      ) {
        this.delete(transaction);
      }
    } else {
      new GC(this.id, this.length).integrate(transaction, 0);
    }
  }
  /**
   * Returns the next non-deleted item
   */
  get next() {
    let n = this.right;
    while (n !== null && n.deleted) {
      n = n.right;
    }
    return n;
  }
  /**
   * Returns the previous non-deleted item
   */
  get prev() {
    let n = this.left;
    while (n !== null && n.deleted) {
      n = n.left;
    }
    return n;
  }
  /**
   * Computes the last content address of this Item.
   */
  get lastId() {
    return this.length === 1 ? this.id : createID(this.id.client, this.id.clock + this.length - 1);
  }
  /**
   * Try to merge two items
   *
   * @param {Item} right
   * @return {boolean}
   */
  mergeWith(right) {
    if (this.constructor === right.constructor && compareIDs(right.origin, this.lastId) && this.right === right && compareIDs(this.rightOrigin, right.rightOrigin) && this.id.client === right.id.client && this.id.clock + this.length === right.id.clock && this.deleted === right.deleted && this.redone === null && right.redone === null && this.content.constructor === right.content.constructor && this.content.mergeWith(right.content)) {
      const searchMarker = (
        /** @type {AbstractType<any>} */
        this.parent._searchMarker
      );
      if (searchMarker) {
        searchMarker.forEach((marker) => {
          if (marker.p === right) {
            marker.p = this;
            if (!this.deleted && this.countable) {
              marker.index -= this.length;
            }
          }
        });
      }
      if (right.keep) {
        this.keep = true;
      }
      this.right = right.right;
      if (this.right !== null) {
        this.right.left = this;
      }
      this.length += right.length;
      return true;
    }
    return false;
  }
  /**
   * Mark this Item as deleted.
   *
   * @param {Transaction} transaction
   */
  delete(transaction) {
    if (!this.deleted) {
      const parent = (
        /** @type {AbstractType<any>} */
        this.parent
      );
      if (this.countable && this.parentSub === null) {
        parent._length -= this.length;
      }
      this.markDeleted();
      addToDeleteSet(transaction.deleteSet, this.id.client, this.id.clock, this.length);
      addChangedTypeToTransaction(transaction, parent, this.parentSub);
      this.content.delete(transaction);
    }
  }
  /**
   * @param {StructStore} store
   * @param {boolean} parentGCd
   */
  gc(store, parentGCd) {
    if (!this.deleted) {
      throw unexpectedCase();
    }
    this.content.gc(store);
    if (parentGCd) {
      replaceStruct(store, this, new GC(this.id, this.length));
    } else {
      this.content = new ContentDeleted(this.length);
    }
  }
  /**
   * Transform the properties of this type to binary and write it to an
   * BinaryEncoder.
   *
   * This is called when this Item is sent to a remote peer.
   *
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder The encoder to write data to.
   * @param {number} offset
   */
  write(encoder, offset) {
    const origin = offset > 0 ? createID(this.id.client, this.id.clock + offset - 1) : this.origin;
    const rightOrigin = this.rightOrigin;
    const parentSub = this.parentSub;
    const info = this.content.getRef() & BITS5 | (origin === null ? 0 : BIT8) | // origin is defined
    (rightOrigin === null ? 0 : BIT7) | // right origin is defined
    (parentSub === null ? 0 : BIT6);
    encoder.writeInfo(info);
    if (origin !== null) {
      encoder.writeLeftID(origin);
    }
    if (rightOrigin !== null) {
      encoder.writeRightID(rightOrigin);
    }
    if (origin === null && rightOrigin === null) {
      const parent = (
        /** @type {AbstractType<any>} */
        this.parent
      );
      if (parent._item !== void 0) {
        const parentItem = parent._item;
        if (parentItem === null) {
          const ykey = findRootTypeKey(parent);
          encoder.writeParentInfo(true);
          encoder.writeString(ykey);
        } else {
          encoder.writeParentInfo(false);
          encoder.writeLeftID(parentItem.id);
        }
      } else if (parent.constructor === String) {
        encoder.writeParentInfo(true);
        encoder.writeString(parent);
      } else if (parent.constructor === ID) {
        encoder.writeParentInfo(false);
        encoder.writeLeftID(parent);
      } else {
        unexpectedCase();
      }
      if (parentSub !== null) {
        encoder.writeString(parentSub);
      }
    }
    this.content.write(encoder, offset);
  }
};
var readItemContent = (decoder, info) => contentRefs[info & BITS5](decoder);
var contentRefs = [
  () => {
    unexpectedCase();
  },
  // GC is not ItemContent
  readContentDeleted,
  // 1
  readContentJSON,
  // 2
  readContentBinary,
  // 3
  readContentString,
  // 4
  readContentEmbed,
  // 5
  readContentFormat,
  // 6
  readContentType,
  // 7
  readContentAny,
  // 8
  readContentDoc,
  // 9
  () => {
    unexpectedCase();
  }
  // 10 - Skip is not ItemContent
];
var structSkipRefNumber = 10;
var Skip = class extends AbstractStruct {
  get deleted() {
    return true;
  }
  delete() {
  }
  /**
   * @param {Skip} right
   * @return {boolean}
   */
  mergeWith(right) {
    if (this.constructor !== right.constructor) {
      return false;
    }
    this.length += right.length;
    return true;
  }
  /**
   * @param {Transaction} transaction
   * @param {number} offset
   */
  integrate(transaction, offset) {
    unexpectedCase();
  }
  /**
   * @param {UpdateEncoderV1 | UpdateEncoderV2} encoder
   * @param {number} offset
   */
  write(encoder, offset) {
    encoder.writeInfo(structSkipRefNumber);
    writeVarUint(encoder.restEncoder, this.length - offset);
  }
  /**
   * @param {Transaction} transaction
   * @param {StructStore} store
   * @return {null | number}
   */
  getMissing(transaction, store) {
    return null;
  }
};
var glo = (
  /** @type {any} */
  typeof globalThis !== "undefined" ? globalThis : typeof window !== "undefined" ? window : typeof global !== "undefined" ? global : {}
);
var importIdentifier = "__ $YJS$ __";
if (glo[importIdentifier] === true) {
  console.error("Yjs was already imported. This breaks constructor checks and will lead to issues! - https://github.com/yjs/yjs/issues/438");
}
glo[importIdentifier] = true;

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/broadcastchannel.js
var channels = /* @__PURE__ */ new Map();
var LocalStoragePolyfill = class {
  /**
   * @param {string} room
   */
  constructor(room) {
    this.room = room;
    this.onmessage = null;
    this._onChange = (e) => e.key === room && this.onmessage !== null && this.onmessage({ data: fromBase64(e.newValue || "") });
    onChange(this._onChange);
  }
  /**
   * @param {ArrayBuffer} buf
   */
  postMessage(buf) {
    varStorage.setItem(this.room, toBase64(createUint8ArrayFromArrayBuffer(buf)));
  }
  close() {
    offChange(this._onChange);
  }
};
var BC = typeof BroadcastChannel === "undefined" ? LocalStoragePolyfill : BroadcastChannel;
var getChannel = (room) => setIfUndefined(channels, room, () => {
  const subs = create2();
  const bc = new BC(room);
  bc.onmessage = (e) => subs.forEach((sub) => sub(e.data, "broadcastchannel"));
  return {
    bc,
    subs
  };
});
var subscribe = (room, f) => {
  getChannel(room).subs.add(f);
  return f;
};
var unsubscribe = (room, f) => {
  const channel = getChannel(room);
  const unsubscribed = channel.subs.delete(f);
  if (unsubscribed && channel.subs.size === 0) {
    channel.bc.close();
    channels.delete(room);
  }
  return unsubscribed;
};
var publish = (room, data, origin = null) => {
  const c = getChannel(room);
  c.bc.postMessage(data);
  c.subs.forEach((sub) => sub(data, origin));
};

// ../../node_modules/.pnpm/y-protocols@1.0.7_yjs@13.6.31/node_modules/y-protocols/sync.js
var messageYjsSyncStep1 = 0;
var messageYjsSyncStep2 = 1;
var messageYjsUpdate = 2;
var writeSyncStep1 = (encoder, doc) => {
  writeVarUint(encoder, messageYjsSyncStep1);
  const sv = encodeStateVector(doc);
  writeVarUint8Array(encoder, sv);
};
var writeSyncStep2 = (encoder, doc, encodedStateVector) => {
  writeVarUint(encoder, messageYjsSyncStep2);
  writeVarUint8Array(encoder, encodeStateAsUpdate(doc, encodedStateVector));
};
var readSyncStep1 = (decoder, encoder, doc) => writeSyncStep2(encoder, doc, readVarUint8Array(decoder));
var readSyncStep2 = (decoder, doc, transactionOrigin, errorHandler) => {
  try {
    applyUpdate(doc, readVarUint8Array(decoder), transactionOrigin);
  } catch (error) {
    if (errorHandler != null) errorHandler(
      /** @type {Error} */
      error
    );
    console.error("Caught error while handling a Yjs update", error);
  }
};
var writeUpdate = (encoder, update) => {
  writeVarUint(encoder, messageYjsUpdate);
  writeVarUint8Array(encoder, update);
};
var readUpdate = readSyncStep2;
var readSyncMessage = (decoder, encoder, doc, transactionOrigin, errorHandler) => {
  const messageType = readVarUint(decoder);
  switch (messageType) {
    case messageYjsSyncStep1:
      readSyncStep1(decoder, encoder, doc);
      break;
    case messageYjsSyncStep2:
      readSyncStep2(decoder, doc, transactionOrigin, errorHandler);
      break;
    case messageYjsUpdate:
      readUpdate(decoder, doc, transactionOrigin, errorHandler);
      break;
    default:
      throw new Error("Unknown message type");
  }
  return messageType;
};

// ../../node_modules/.pnpm/y-protocols@1.0.7_yjs@13.6.31/node_modules/y-protocols/auth.js
var messagePermissionDenied = 0;
var readAuthMessage = (decoder, y, permissionDeniedHandler2) => {
  switch (readVarUint(decoder)) {
    case messagePermissionDenied:
      permissionDeniedHandler2(y, readVarString(decoder));
  }
};

// ../../node_modules/.pnpm/y-protocols@1.0.7_yjs@13.6.31/node_modules/y-protocols/awareness.js
var outdatedTimeout = 3e4;
var Awareness = class extends Observable {
  /**
   * @param {Y.Doc} doc
   */
  constructor(doc) {
    super();
    this.doc = doc;
    this.clientID = doc.clientID;
    this.states = /* @__PURE__ */ new Map();
    this.meta = /* @__PURE__ */ new Map();
    this._checkInterval = /** @type {any} */
    setInterval(() => {
      const now = getUnixTime();
      if (this.getLocalState() !== null && outdatedTimeout / 2 <= now - /** @type {{lastUpdated:number}} */
      this.meta.get(this.clientID).lastUpdated) {
        this.setLocalState(this.getLocalState());
      }
      const remove = [];
      this.meta.forEach((meta, clientid) => {
        if (clientid !== this.clientID && outdatedTimeout <= now - meta.lastUpdated && this.states.has(clientid)) {
          remove.push(clientid);
        }
      });
      if (remove.length > 0) {
        removeAwarenessStates(this, remove, "timeout");
      }
    }, floor(outdatedTimeout / 10));
    doc.on("destroy", () => {
      this.destroy();
    });
    this.setLocalState({});
  }
  destroy() {
    this.emit("destroy", [this]);
    this.setLocalState(null);
    super.destroy();
    clearInterval(this._checkInterval);
  }
  /**
   * @return {Object<string,any>|null}
   */
  getLocalState() {
    return this.states.get(this.clientID) || null;
  }
  /**
   * @param {Object<string,any>|null} state
   */
  setLocalState(state) {
    const clientID = this.clientID;
    const currLocalMeta = this.meta.get(clientID);
    const clock = currLocalMeta === void 0 ? 0 : currLocalMeta.clock + 1;
    const prevState = this.states.get(clientID);
    if (state === null) {
      this.states.delete(clientID);
    } else {
      this.states.set(clientID, state);
    }
    this.meta.set(clientID, {
      clock,
      lastUpdated: getUnixTime()
    });
    const added = [];
    const updated = [];
    const filteredUpdated = [];
    const removed = [];
    if (state === null) {
      removed.push(clientID);
    } else if (prevState == null) {
      if (state != null) {
        added.push(clientID);
      }
    } else {
      updated.push(clientID);
      if (!equalityDeep(prevState, state)) {
        filteredUpdated.push(clientID);
      }
    }
    if (added.length > 0 || filteredUpdated.length > 0 || removed.length > 0) {
      this.emit("change", [{ added, updated: filteredUpdated, removed }, "local"]);
    }
    this.emit("update", [{ added, updated, removed }, "local"]);
  }
  /**
   * @param {string} field
   * @param {any} value
   */
  setLocalStateField(field, value) {
    const state = this.getLocalState();
    if (state !== null) {
      this.setLocalState({
        ...state,
        [field]: value
      });
    }
  }
  /**
   * @return {Map<number,Object<string,any>>}
   */
  getStates() {
    return this.states;
  }
};
var removeAwarenessStates = (awareness, clients, origin) => {
  const removed = [];
  for (let i = 0; i < clients.length; i++) {
    const clientID = clients[i];
    if (awareness.states.has(clientID)) {
      awareness.states.delete(clientID);
      if (clientID === awareness.clientID) {
        const curMeta = (
          /** @type {MetaClientState} */
          awareness.meta.get(clientID)
        );
        awareness.meta.set(clientID, {
          clock: curMeta.clock + 1,
          lastUpdated: getUnixTime()
        });
      }
      removed.push(clientID);
    }
  }
  if (removed.length > 0) {
    awareness.emit("change", [{ added: [], updated: [], removed }, origin]);
    awareness.emit("update", [{ added: [], updated: [], removed }, origin]);
  }
};
var encodeAwarenessUpdate = (awareness, clients, states = awareness.states) => {
  const len = clients.length;
  const encoder = createEncoder();
  writeVarUint(encoder, len);
  for (let i = 0; i < len; i++) {
    const clientID = clients[i];
    const state = states.get(clientID) || null;
    const clock = (
      /** @type {MetaClientState} */
      awareness.meta.get(clientID).clock
    );
    writeVarUint(encoder, clientID);
    writeVarUint(encoder, clock);
    writeVarString(encoder, JSON.stringify(state));
  }
  return toUint8Array(encoder);
};
var applyAwarenessUpdate = (awareness, update, origin) => {
  const decoder = createDecoder(update);
  const timestamp = getUnixTime();
  const added = [];
  const updated = [];
  const filteredUpdated = [];
  const removed = [];
  const len = readVarUint(decoder);
  for (let i = 0; i < len; i++) {
    const clientID = readVarUint(decoder);
    let clock = readVarUint(decoder);
    const state = JSON.parse(readVarString(decoder));
    const clientMeta = awareness.meta.get(clientID);
    const prevState = awareness.states.get(clientID);
    const currClock = clientMeta === void 0 ? 0 : clientMeta.clock;
    if (currClock < clock || currClock === clock && state === null && awareness.states.has(clientID)) {
      if (state === null) {
        if (clientID === awareness.clientID && awareness.getLocalState() != null) {
          clock++;
        } else {
          awareness.states.delete(clientID);
        }
      } else {
        awareness.states.set(clientID, state);
      }
      awareness.meta.set(clientID, {
        clock,
        lastUpdated: timestamp
      });
      if (clientMeta === void 0 && state !== null) {
        added.push(clientID);
      } else if (clientMeta !== void 0 && state === null) {
        removed.push(clientID);
      } else if (state !== null) {
        if (!equalityDeep(state, prevState)) {
          filteredUpdated.push(clientID);
        }
        updated.push(clientID);
      }
    }
  }
  if (added.length > 0 || filteredUpdated.length > 0 || removed.length > 0) {
    awareness.emit("change", [{
      added,
      updated: filteredUpdated,
      removed
    }, origin]);
  }
  if (added.length > 0 || updated.length > 0 || removed.length > 0) {
    awareness.emit("update", [{
      added,
      updated,
      removed
    }, origin]);
  }
};

// ../../node_modules/.pnpm/lib0@0.2.117/node_modules/lib0/url.js
var encodeQueryParams = (params2) => map(params2, (val, key2) => `${encodeURIComponent(key2)}=${encodeURIComponent(val)}`).join("&");

// ../../node_modules/.pnpm/y-websocket@2.1.0_bufferutil@4.1.0_yjs@13.6.31/node_modules/y-websocket/src/y-websocket.js
var messageSync = 0;
var messageQueryAwareness = 3;
var messageAwareness = 1;
var messageAuth = 2;
var messageHandlers = [];
messageHandlers[messageSync] = (encoder, decoder, provider, emitSynced, _messageType) => {
  writeVarUint(encoder, messageSync);
  const syncMessageType = readSyncMessage(
    decoder,
    encoder,
    provider.doc,
    provider
  );
  if (emitSynced && syncMessageType === messageYjsSyncStep2 && !provider.synced) {
    provider.synced = true;
  }
};
messageHandlers[messageQueryAwareness] = (encoder, _decoder, provider, _emitSynced, _messageType) => {
  writeVarUint(encoder, messageAwareness);
  writeVarUint8Array(
    encoder,
    encodeAwarenessUpdate(
      provider.awareness,
      Array.from(provider.awareness.getStates().keys())
    )
  );
};
messageHandlers[messageAwareness] = (_encoder, decoder, provider, _emitSynced, _messageType) => {
  applyAwarenessUpdate(
    provider.awareness,
    readVarUint8Array(decoder),
    provider
  );
};
messageHandlers[messageAuth] = (_encoder, decoder, provider, _emitSynced, _messageType) => {
  readAuthMessage(
    decoder,
    provider.doc,
    (_ydoc, reason) => permissionDeniedHandler(provider, reason)
  );
};
var messageReconnectTimeout = 3e4;
var permissionDeniedHandler = (provider, reason) => console.warn(`Permission denied to access ${provider.url}.
${reason}`);
var readMessage = (provider, buf, emitSynced) => {
  const decoder = createDecoder(buf);
  const encoder = createEncoder();
  const messageType = readVarUint(decoder);
  const messageHandler = provider.messageHandlers[messageType];
  if (
    /** @type {any} */
    messageHandler
  ) {
    messageHandler(encoder, decoder, provider, emitSynced, messageType);
  } else {
    console.error("Unable to compute message");
  }
  return encoder;
};
var closeWebsocketConnection = (provider, ws, event) => {
  if (ws === provider.ws) {
    provider.emit("connection-close", [event, provider]);
    provider.ws = null;
    ws.close();
    provider.wsconnecting = false;
    if (provider.wsconnected) {
      provider.wsconnected = false;
      provider.synced = false;
      removeAwarenessStates(
        provider.awareness,
        Array.from(provider.awareness.getStates().keys()).filter(
          (client) => client !== provider.doc.clientID
        ),
        provider
      );
      provider.emit("status", [{
        status: "disconnected"
      }]);
    } else {
      provider.wsUnsuccessfulReconnects++;
    }
    setTimeout(
      setupWS,
      min(
        pow(2, provider.wsUnsuccessfulReconnects) * 100,
        provider.maxBackoffTime
      ),
      provider
    );
  }
};
var setupWS = (provider) => {
  if (provider.shouldConnect && provider.ws === null) {
    const websocket = new provider._WS(provider.url, provider.protocols);
    websocket.binaryType = "arraybuffer";
    provider.ws = websocket;
    provider.wsconnecting = true;
    provider.wsconnected = false;
    provider.synced = false;
    websocket.onmessage = (event) => {
      provider.wsLastMessageReceived = getUnixTime();
      const encoder = readMessage(provider, new Uint8Array(event.data), true);
      if (length(encoder) > 1) {
        websocket.send(toUint8Array(encoder));
      }
    };
    websocket.onerror = (event) => {
      provider.emit("connection-error", [event, provider]);
    };
    websocket.onclose = (event) => {
      closeWebsocketConnection(provider, websocket, event);
    };
    websocket.onopen = () => {
      provider.wsLastMessageReceived = getUnixTime();
      provider.wsconnecting = false;
      provider.wsconnected = true;
      provider.wsUnsuccessfulReconnects = 0;
      provider.emit("status", [{
        status: "connected"
      }]);
      const encoder = createEncoder();
      writeVarUint(encoder, messageSync);
      writeSyncStep1(encoder, provider.doc);
      websocket.send(toUint8Array(encoder));
      if (provider.awareness.getLocalState() !== null) {
        const encoderAwarenessState = createEncoder();
        writeVarUint(encoderAwarenessState, messageAwareness);
        writeVarUint8Array(
          encoderAwarenessState,
          encodeAwarenessUpdate(provider.awareness, [
            provider.doc.clientID
          ])
        );
        websocket.send(toUint8Array(encoderAwarenessState));
      }
    };
    provider.emit("status", [{
      status: "connecting"
    }]);
  }
};
var broadcastMessage = (provider, buf) => {
  const ws = provider.ws;
  if (provider.wsconnected && ws && ws.readyState === ws.OPEN) {
    ws.send(buf);
  }
  if (provider.bcconnected) {
    publish(provider.bcChannel, buf, provider);
  }
};
var WebsocketProvider = class extends ObservableV2 {
  /**
   * @param {string} serverUrl
   * @param {string} roomname
   * @param {Y.Doc} doc
   * @param {object} opts
   * @param {boolean} [opts.connect]
   * @param {awarenessProtocol.Awareness} [opts.awareness]
   * @param {Object<string,string>} [opts.params] specify url parameters
   * @param {Array<string>} [opts.protocols] specify websocket protocols
   * @param {typeof WebSocket} [opts.WebSocketPolyfill] Optionall provide a WebSocket polyfill
   * @param {number} [opts.resyncInterval] Request server state every `resyncInterval` milliseconds
   * @param {number} [opts.maxBackoffTime] Maximum amount of time to wait before trying to reconnect (we try to reconnect using exponential backoff)
   * @param {boolean} [opts.disableBc] Disable cross-tab BroadcastChannel communication
   */
  constructor(serverUrl, roomname, doc, {
    connect = true,
    awareness = new Awareness(doc),
    params: params2 = {},
    protocols = [],
    WebSocketPolyfill = WebSocket,
    resyncInterval = -1,
    maxBackoffTime = 2500,
    disableBc = false
  } = {}) {
    super();
    while (serverUrl[serverUrl.length - 1] === "/") {
      serverUrl = serverUrl.slice(0, serverUrl.length - 1);
    }
    this.serverUrl = serverUrl;
    this.bcChannel = serverUrl + "/" + roomname;
    this.maxBackoffTime = maxBackoffTime;
    this.params = params2;
    this.protocols = protocols;
    this.roomname = roomname;
    this.doc = doc;
    this._WS = WebSocketPolyfill;
    this.awareness = awareness;
    this.wsconnected = false;
    this.wsconnecting = false;
    this.bcconnected = false;
    this.disableBc = disableBc;
    this.wsUnsuccessfulReconnects = 0;
    this.messageHandlers = messageHandlers.slice();
    this._synced = false;
    this.ws = null;
    this.wsLastMessageReceived = 0;
    this.shouldConnect = connect;
    this._resyncInterval = 0;
    if (resyncInterval > 0) {
      this._resyncInterval = /** @type {any} */
      setInterval(() => {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
          const encoder = createEncoder();
          writeVarUint(encoder, messageSync);
          writeSyncStep1(encoder, doc);
          this.ws.send(toUint8Array(encoder));
        }
      }, resyncInterval);
    }
    this._bcSubscriber = (data, origin) => {
      if (origin !== this) {
        const encoder = readMessage(this, new Uint8Array(data), false);
        if (length(encoder) > 1) {
          publish(this.bcChannel, toUint8Array(encoder), this);
        }
      }
    };
    this._updateHandler = (update, origin) => {
      if (origin !== this) {
        const encoder = createEncoder();
        writeVarUint(encoder, messageSync);
        writeUpdate(encoder, update);
        broadcastMessage(this, toUint8Array(encoder));
      }
    };
    this.doc.on("update", this._updateHandler);
    this._awarenessUpdateHandler = ({ added, updated, removed }, _origin) => {
      const changedClients = added.concat(updated).concat(removed);
      const encoder = createEncoder();
      writeVarUint(encoder, messageAwareness);
      writeVarUint8Array(
        encoder,
        encodeAwarenessUpdate(awareness, changedClients)
      );
      broadcastMessage(this, toUint8Array(encoder));
    };
    this._exitHandler = () => {
      removeAwarenessStates(
        this.awareness,
        [doc.clientID],
        "app closed"
      );
    };
    if (isNode && typeof process !== "undefined") {
      process.on("exit", this._exitHandler);
    }
    awareness.on("update", this._awarenessUpdateHandler);
    this._checkInterval = /** @type {any} */
    setInterval(() => {
      if (this.wsconnected && messageReconnectTimeout < getUnixTime() - this.wsLastMessageReceived) {
        closeWebsocketConnection(
          this,
          /** @type {WebSocket} */
          this.ws,
          null
        );
      }
    }, messageReconnectTimeout / 10);
    if (connect) {
      this.connect();
    }
  }
  get url() {
    const encodedParams = encodeQueryParams(this.params);
    return this.serverUrl + "/" + this.roomname + (encodedParams.length === 0 ? "" : "?" + encodedParams);
  }
  /**
   * @type {boolean}
   */
  get synced() {
    return this._synced;
  }
  set synced(state) {
    if (this._synced !== state) {
      this._synced = state;
      this.emit("synced", [state]);
      this.emit("sync", [state]);
    }
  }
  destroy() {
    if (this._resyncInterval !== 0) {
      clearInterval(this._resyncInterval);
    }
    clearInterval(this._checkInterval);
    this.disconnect();
    if (isNode && typeof process !== "undefined") {
      process.off("exit", this._exitHandler);
    }
    this.awareness.off("update", this._awarenessUpdateHandler);
    this.doc.off("update", this._updateHandler);
    super.destroy();
  }
  connectBc() {
    if (this.disableBc) {
      return;
    }
    if (!this.bcconnected) {
      subscribe(this.bcChannel, this._bcSubscriber);
      this.bcconnected = true;
    }
    const encoderSync = createEncoder();
    writeVarUint(encoderSync, messageSync);
    writeSyncStep1(encoderSync, this.doc);
    publish(this.bcChannel, toUint8Array(encoderSync), this);
    const encoderState = createEncoder();
    writeVarUint(encoderState, messageSync);
    writeSyncStep2(encoderState, this.doc);
    publish(this.bcChannel, toUint8Array(encoderState), this);
    const encoderAwarenessQuery = createEncoder();
    writeVarUint(encoderAwarenessQuery, messageQueryAwareness);
    publish(
      this.bcChannel,
      toUint8Array(encoderAwarenessQuery),
      this
    );
    const encoderAwarenessState = createEncoder();
    writeVarUint(encoderAwarenessState, messageAwareness);
    writeVarUint8Array(
      encoderAwarenessState,
      encodeAwarenessUpdate(this.awareness, [
        this.doc.clientID
      ])
    );
    publish(
      this.bcChannel,
      toUint8Array(encoderAwarenessState),
      this
    );
  }
  disconnectBc() {
    const encoder = createEncoder();
    writeVarUint(encoder, messageAwareness);
    writeVarUint8Array(
      encoder,
      encodeAwarenessUpdate(this.awareness, [
        this.doc.clientID
      ], /* @__PURE__ */ new Map())
    );
    broadcastMessage(this, toUint8Array(encoder));
    if (this.bcconnected) {
      unsubscribe(this.bcChannel, this._bcSubscriber);
      this.bcconnected = false;
    }
  }
  disconnect() {
    this.shouldConnect = false;
    this.disconnectBc();
    if (this.ws !== null) {
      closeWebsocketConnection(this, this.ws, null);
    }
  }
  connect() {
    this.shouldConnect = true;
    if (!this.wsconnected && this.ws === null) {
      setupWS(this);
      this.connectBc();
    }
  }
};

// agent/participant.ts
import { appendFileSync } from "node:fs";

// editor/collab/access/capabilities.ts
var ALG = { name: "ECDSA", namedCurve: "P-256" };
var SIGN = { name: "ECDSA", hash: "SHA-256" };
function subtle2() {
  const c = globalThis.crypto?.subtle;
  if (!c) throw new Error("Web Crypto (crypto.subtle) unavailable - needs a secure context");
  return c;
}
function toB64(input) {
  const bytes = input instanceof Uint8Array ? input : new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return typeof btoa !== "undefined" ? btoa(bin) : Buffer.from(bin, "binary").toString("base64");
}
function fromB64(s) {
  const bin = typeof atob !== "undefined" ? atob(s) : Buffer.from(s, "base64").toString("binary");
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}
var utf8 = (s) => new TextEncoder().encode(s);
var src = (u) => u;
var WILDCARD_SUBJECT = "*";
async function generateKeyPair() {
  const kp = await subtle2().generateKey(ALG, true, ["sign", "verify"]);
  return { publicKey: kp.publicKey, privateKey: kp.privateKey };
}
async function exportPublicKey(key2) {
  return toB64(await subtle2().exportKey("raw", key2));
}
async function importPublicKey(b64) {
  return subtle2().importKey("raw", src(fromB64(b64)), ALG, true, ["verify"]);
}
var pubKeys = /* @__PURE__ */ new Map();
function cachedPublicKey(b64) {
  let k = pubKeys.get(b64);
  if (!k) {
    k = importPublicKey(b64);
    k.catch(() => pubKeys.delete(b64));
    pubKeys.set(b64, k);
  }
  return k;
}
async function sign(priv, data) {
  return toB64(await subtle2().sign(SIGN, priv, src(data)));
}
async function verify(pub, sig, data) {
  return subtle2().verify(SIGN, pub, src(fromB64(sig)), src(data));
}
function capBytes(c) {
  return utf8(JSON.stringify([c.docId, c.subject, c.permission, c.iat, c.exp ?? 0]));
}
var capVerdicts = /* @__PURE__ */ new Map();
var CAP_VERDICTS_MAX = 4096;
async function verifyCapability(sc, ownerPublicKeyB64, docId, now = Date.now()) {
  if (!sc?.cap || sc.cap.docId !== docId) return false;
  if (sc.cap.exp != null && now > sc.cap.exp) return false;
  if (sc.via && sc.via.cap?.exp != null && now > sc.via.cap.exp) return false;
  const key2 = JSON.stringify([ownerPublicKeyB64, sc.sig, sc.cap, sc.via ? [sc.via.sig, sc.via.cap] : null]);
  let v = capVerdicts.get(key2);
  if (!v) {
    if (capVerdicts.size >= CAP_VERDICTS_MAX) capVerdicts.clear();
    v = verifyCapabilitySigs(sc, ownerPublicKeyB64, docId).catch(() => false);
    capVerdicts.set(key2, v);
  }
  return v;
}
async function verifyCapabilitySigs(sc, ownerPublicKeyB64, docId) {
  if (sc.via) {
    if (sc.cap.permission === "own" /* Own */) return false;
    const d = sc.via;
    if (!d?.cap || d.cap.docId !== docId || d.cap.permission !== "own" /* Own */) return false;
    const rootPub = await cachedPublicKey(ownerPublicKeyB64);
    if (!await verify(rootPub, d.sig, capBytes(d.cap))) return false;
    const delegatedPub = await cachedPublicKey(d.cap.subject);
    return verify(delegatedPub, sc.sig, capBytes(sc.cap));
  }
  const ownerPub = await cachedPublicKey(ownerPublicKeyB64);
  return verify(ownerPub, sc.sig, capBytes(sc.cap));
}
function updateBytes(docId, updateB64) {
  return utf8(`${docId}|${updateB64}`);
}
async function sealUpdate(authorPriv, authorPublicKeyB64, docId, update, cap) {
  const updateB64 = toB64(update);
  return {
    docId,
    author: authorPublicKeyB64,
    update: updateB64,
    sig: await sign(authorPriv, updateBytes(docId, updateB64)),
    cap
  };
}
async function authorizeUpdate(env, ownerPublicKeyB64, docId, now = Date.now()) {
  if (!env || env.docId !== docId) return null;
  const subject = env.cap?.cap?.subject;
  if (subject !== WILDCARD_SUBJECT && subject !== env.author) return null;
  if (env.cap.cap.permission !== "edit" /* Edit */ && env.cap.cap.permission !== "suggest" /* Suggest */) return null;
  if (!await verifyCapability(env.cap, ownerPublicKeyB64, docId, now)) return null;
  const authorPub = await cachedPublicKey(env.author);
  if (!await verify(authorPub, env.sig, updateBytes(env.docId, env.update))) return null;
  return fromB64(env.update);
}
function revocationBytes(r) {
  return utf8(JSON.stringify(["revoke", r.docId, r.author, r.capSig, r.after]));
}
async function issueRevocation(ownerPriv, docId, author, capSig, after) {
  const body = { docId, author, capSig, after };
  return { ...body, sig: await sign(ownerPriv, revocationBytes(body)) };
}
async function verifyRevocation(r, ownerPublicKeyB64, docId) {
  if (!r || r.docId !== docId || typeof r.after !== "number" || r.after < 0) return false;
  try {
    return await verify(await importPublicKey(ownerPublicKeyB64), r.sig, revocationBytes(r));
  } catch {
    return false;
  }
}
function modeBytes(r) {
  const after = Object.keys(r.after).sort().map((k) => [k, r.after[k]]);
  return utf8(JSON.stringify(["mode", r.docId, r.mode, r.seq, after]));
}
async function verifyModeRecord(r, ownerPublicKeyB64, docId) {
  if (!r || r.docId !== docId || typeof r.seq !== "number" || !r.after || typeof r.after !== "object") return false;
  if (r.mode !== "edit" /* Edit */ && r.mode !== "review" /* Review */) return false;
  try {
    return await verify(await importPublicKey(ownerPublicKeyB64), r.sig, modeBytes(r));
  } catch {
    return false;
  }
}
function modeAt(records, pairKey, pos) {
  let mode = "edit" /* Edit */;
  for (const r of records) if (pos > (r.after[pairKey] ?? 0)) mode = r.mode;
  return mode;
}

// editor/core/mesh/roomKey.ts
var IV_LEN = 12;
var KEY_BYTES = 32;
function ab(b) {
  const out = new ArrayBuffer(b.byteLength);
  new Uint8Array(out).set(b);
  return out;
}
function fromB64url(s) {
  const pad = s.length % 4 === 0 ? "" : "=".repeat(4 - s.length % 4);
  const bin = atob(s.replace(/-/g, "+").replace(/_/g, "/") + pad);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}
async function roomKeyFromFragment(fragment) {
  try {
    const raw = fromB64url(fragment);
    if (raw.length !== KEY_BYTES) return null;
    return await crypto.subtle.importKey("raw", ab(raw), { name: "AES-GCM", length: 256 }, false, ["encrypt", "decrypt"]);
  } catch {
    return null;
  }
}
var te = new TextEncoder();
async function sealUpdate2(key2, plaintext, aad) {
  const iv = crypto.getRandomValues(new Uint8Array(IV_LEN));
  const params2 = { name: "AES-GCM", iv: ab(iv) };
  if (aad) params2.additionalData = ab(aad);
  const ct = new Uint8Array(await crypto.subtle.encrypt(params2, key2, ab(plaintext)));
  const out = new Uint8Array(IV_LEN + ct.length);
  out.set(iv, 0);
  out.set(ct, IV_LEN);
  return out;
}
async function openUpdate(key2, framed, aad) {
  if (framed.length < IV_LEN + 16) return null;
  const iv = framed.subarray(0, IV_LEN);
  const ct = framed.subarray(IV_LEN);
  const params2 = { name: "AES-GCM", iv: ab(iv) };
  if (aad) params2.additionalData = ab(aad);
  try {
    return new Uint8Array(await crypto.subtle.decrypt(params2, key2, ab(ct)));
  } catch {
    return null;
  }
}

// editor/collab/access/reviewGate.ts
var SUGGESTIONS = "suggestions";
var RUNS = "runs";
var REVIEW_MAPS = [SUGGESTIONS, RUNS];
var VALUE_CONTENT = /* @__PURE__ */ new Set(["ContentAny", "ContentDeleted"]);
function touchesOnlySuggestions(doc, update) {
  const maps = new Set(REVIEW_MAPS.map((n) => doc.getMap(n)));
  const { structs, ds } = decodeUpdate(update);
  const local = structs.filter((s) => s.constructor.name === "Item");
  const inUpdate = (id2) => local.find((s) => s.id.client === id2.client && id2.clock >= s.id.clock && id2.clock < s.id.clock + s.length);
  const inDoc = (id2) => {
    try {
      return getItem(doc.store, createID(id2.client, id2.clock));
    } catch {
      return null;
    }
  };
  const underSuggestions = (s, depth = 0) => {
    if (depth > 64) return false;
    if (typeof s.parent === "string") return REVIEW_MAPS.includes(s.parent);
    if (maps.has(s.parent)) return true;
    if (s.parent) return false;
    const ref = s.origin ?? s.rightOrigin;
    if (!ref) return false;
    const next = inUpdate(ref) ?? inDoc(ref);
    return !!next && underSuggestions(next, depth + 1);
  };
  for (const s of structs) {
    if (s.constructor.name !== "Item") continue;
    if (!VALUE_CONTENT.has(s.content.constructor.name)) return false;
    if (!underSuggestions(s)) return false;
  }
  for (const [client, ranges] of ds.clients) {
    for (const { clock, len } of ranges) {
      for (let c = clock; c < clock + len; ) {
        const it = inDoc({ client, clock: c }) ?? inUpdate({ client, clock: c });
        if (!it || !underSuggestions(it)) return false;
        c = it.id.clock + it.length;
      }
    }
  }
  return true;
}

// editor/collab/access/authorizedSync.ts
var ORIGIN = "authorized-sync";
var REPLAY_CHUNK = 256;
function bridgeAuthorizedSync(appDoc, wire, ctx, onReject) {
  const applied = /* @__PURE__ */ new Set();
  const pairKey = (author, capSig) => `${author}|${capSig}`;
  const position = /* @__PURE__ */ new Map();
  const counts = /* @__PURE__ */ new Map();
  const revoked = /* @__PURE__ */ new Map();
  const isCut = (author, capSig, pos) => {
    const after = revoked.get(pairKey(author, capSig));
    return after !== void 0 && pos > after;
  };
  const aad = ctx.roomKey ? new TextEncoder().encode(ctx.docId) : void 0;
  let modes = [];
  const isOwnerKey = (k) => k === ctx.ownerPublicKey;
  const currentMode = () => modes.length ? modes[modes.length - 1].mode : "edit" /* Edit */;
  const reviewing = (author, capPermission) => capPermission === "edit" /* Edit */ && !isOwnerKey(author) && currentMode() === "review" /* Review */;
  const onLocal = (update, origin) => {
    if (origin === ORIGIN) return;
    if (!ctx.myCapability) return;
    if (revoked.has(pairKey(ctx.myPublicKey, ctx.myCapability.sig))) return;
    if ((ctx.myCapability.cap.permission === "suggest" /* Suggest */ || reviewing(ctx.myPublicKey, ctx.myCapability.cap.permission)) && !touchesOnlySuggestions(appDoc, update)) return;
    void (async () => {
      const payload = ctx.roomKey ? await sealUpdate2(ctx.roomKey, update, aad) : update;
      const env = await sealUpdate(
        ctx.myPrivateKey,
        ctx.myPublicKey,
        ctx.docId,
        payload,
        ctx.myCapability
      );
      applied.add(env.sig);
      wire.push([env]);
    })();
  };
  appDoc.on("update", onLocal);
  const queued = /* @__PURE__ */ new Set();
  let tail = Promise.resolve();
  const open = async (env) => {
    const payload = await authorizeUpdate(env, ctx.ownerPublicKey, ctx.docId);
    if (!payload) return null;
    return ctx.roomKey ? await openUpdate(ctx.roomKey, payload, aad) : payload;
  };
  const applyChunk = (envs, updates) => {
    appDoc.transact(() => {
      envs.forEach((env, i) => {
        const update = updates[i];
        if (!update || applied.has(env.sig)) {
          if (!update) onReject?.(env);
          return;
        }
        if (env.cap.cap.permission === "suggest" /* Suggest */ && !touchesOnlySuggestions(appDoc, update)) {
          onReject?.(env);
          return;
        }
        if (!position.has(env.sig)) {
          const k = pairKey(env.author, env.cap.sig);
          const n = (counts.get(k) ?? 0) + 1;
          counts.set(k, n);
          position.set(env.sig, n);
        }
        if (isCut(env.author, env.cap.sig, position.get(env.sig))) {
          onReject?.(env);
          return;
        }
        if (env.cap.cap.permission === "edit" /* Edit */ && !isOwnerKey(env.author) && modeAt(modes, pairKey(env.author, env.cap.sig), position.get(env.sig)) === "review" /* Review */ && !touchesOnlySuggestions(appDoc, update)) {
          onReject?.(env);
          return;
        }
        applied.add(env.sig);
        applyUpdate(appDoc, update, ORIGIN);
      });
    }, ORIGIN);
  };
  const consume = (envs) => {
    const fresh = envs.filter((e) => e && !applied.has(e.sig) && !queued.has(e.sig));
    for (const e of fresh) queued.add(e.sig);
    const run = tail.then(async () => {
      try {
        for (let i = 0; i < fresh.length; i += REPLAY_CHUNK) {
          const chunk = fresh.slice(i, i + REPLAY_CHUNK);
          applyChunk(chunk, await Promise.all(chunk.map((e) => open(e).catch(() => null))));
        }
      } finally {
        for (const e of fresh) queued.delete(e.sig);
      }
    });
    tail = run.catch(() => {
    });
    return run;
  };
  const onWire = (event) => {
    const added = [];
    for (const d of event.changes.delta) {
      if (d.insert) added.push(...d.insert);
    }
    void consume(added);
  };
  wire.observe(onWire);
  const revocationListeners = /* @__PURE__ */ new Set();
  const addRevocations = async (list) => {
    let changed = false;
    for (const rv of list) {
      if (!await verifyRevocation(rv, ctx.ownerPublicKey, ctx.docId)) continue;
      const k = pairKey(rv.author, rv.capSig);
      revoked.set(k, Math.min(revoked.get(k) ?? Infinity, rv.after));
      changed = true;
    }
    if (changed) for (const fn of revocationListeners) fn();
  };
  const onRevoke = (event) => {
    const added = [];
    for (const d of event.changes.delta) if (d.insert) added.push(...d.insert);
    void addRevocations(added);
  };
  ctx.revocations?.observe(onRevoke);
  const modeListeners = /* @__PURE__ */ new Set();
  const addModes = async (list) => {
    let changed = false;
    for (const r of list) {
      if (modes.some((m) => m.sig === r.sig)) continue;
      if (!await verifyModeRecord(r, ctx.ownerPublicKey, ctx.docId)) continue;
      modes = [...modes, r].sort((a, b) => a.seq - b.seq);
      changed = true;
    }
    if (changed) for (const fn of modeListeners) fn();
  };
  const onModes = (event) => {
    const added = [];
    for (const d of event.changes.delta) if (d.insert) added.push(...d.insert);
    void addModes(added);
  };
  ctx.modes?.observe(onModes);
  const drain = async () => {
    if (ctx.revocations) await addRevocations(ctx.revocations.toArray());
    if (ctx.modes) await addModes(ctx.modes.toArray());
    await consume(wire.toArray());
  };
  void drain();
  return {
    teardown: () => {
      appDoc.off("update", onLocal);
      wire.unobserve(onWire);
      ctx.revocations?.unobserve(onRevoke);
      ctx.modes?.unobserve(onModes);
    },
    drain,
    isRevoked: (author, capSig) => revoked.has(pairKey(author, capSig)),
    onRevocation: (fn) => {
      revocationListeners.add(fn);
      return () => revocationListeners.delete(fn);
    },
    docMode: currentMode,
    allCounts: () => Object.fromEntries(counts),
    lastModeSeq: () => modes.length ? modes[modes.length - 1].seq : 0,
    onDocMode: (fn) => {
      modeListeners.add(fn);
      return () => modeListeners.delete(fn);
    },
    usage: (author) => {
      const out = /* @__PURE__ */ new Map();
      for (const [k, n] of counts) {
        const [a, capSig] = k.split("|");
        if (a === author) out.set(capSig, n);
      }
      return out;
    }
  };
}

// editor/collab/share/sharePassword.ts
var enc = new TextEncoder();
var dec = new TextDecoder();
function isLockedSecrets(x) {
  if (!x || typeof x !== "object") return false;
  const l = x;
  return l.v === 1 && typeof l.it === "number" && l.it >= 1 && l.it <= 1e7 && typeof l.salt === "string" && typeof l.iv === "string" && typeof l.ct === "string";
}

// editor/collab/share/shareLink.ts
var SHARE_TTL_MS = 24 * 60 * 60 * 1e3;
function b64urlEncode(s) {
  const bytes = new TextEncoder().encode(s);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  const b64 = typeof btoa !== "undefined" ? btoa(bin) : Buffer.from(bin, "binary").toString("base64");
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function b64urlDecode(token) {
  const b64 = token.replace(/-/g, "+").replace(/_/g, "/");
  const bin = typeof atob !== "undefined" ? atob(b64) : Buffer.from(b64, "base64").toString("binary");
  const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}
function encodeShare(fields, opts) {
  const now = opts?.now ?? Date.now();
  const payload = {
    v: 1,
    docKey: fields.docKey,
    name: fields.name,
    kind: fields.kind,
    owner: fields.owner,
    exp: now + (opts?.ttlMs ?? SHARE_TTL_MS),
    ownerKey: fields.ownerKey,
    roomKey: fields.roomKey,
    cap: fields.cap,
    ...fields.smdGated ? { smdGated: true } : {},
    ...fields.noSave ? { noSave: true } : {},
    ...fields.locked ? { locked: fields.locked } : {}
  };
  return b64urlEncode(JSON.stringify(payload));
}
function decodeShare(token, now = Date.now()) {
  let raw;
  try {
    raw = JSON.parse(b64urlDecode(token));
  } catch {
    return { ok: false, reason: "malformed" };
  }
  if (!raw || typeof raw !== "object") return { ok: false, reason: "malformed" };
  const p = raw;
  if (p.v !== 1) return { ok: false, reason: "version" };
  if (typeof p.docKey !== "string" || !p.docKey) return { ok: false, reason: "malformed" };
  if (typeof p.name !== "string" || typeof p.kind !== "string" || typeof p.owner !== "string") {
    return { ok: false, reason: "malformed" };
  }
  if (typeof p.exp !== "number" || now > p.exp) return { ok: false, reason: "expired" };
  if (p.locked !== void 0 && !isLockedSecrets(p.locked)) return { ok: false, reason: "malformed" };
  return { ok: true, payload: p };
}
function shareTokenFromHash(hash) {
  const m = /^#\/(?:room|share|s)\/(.+)$/.exec(hash.trim());
  return m ? m[1] : null;
}
function tokenFromInput(input) {
  const raw = input.trim();
  if (!raw) return null;
  const hashAt = raw.indexOf("#");
  if (hashAt >= 0) return shareTokenFromHash(raw.slice(hashAt));
  return /^[A-Za-z0-9_-]{24,}$/.test(raw) ? raw : null;
}

// editor/collab/share/shareCode.ts
var SHARE_CODE_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
var SHARE_CODE_LEN = 8;
function normShareCode(raw) {
  const s = raw.toUpperCase().replace(/[\s-]/g, "").replace(/O/g, "0").replace(/[IL]/g, "1");
  if (s.length !== SHARE_CODE_LEN) return null;
  for (const ch of s) if (!SHARE_CODE_ALPHABET.includes(ch)) return null;
  return s;
}
function httpBase(relay) {
  const base = relay.trim().replace(/\/+$/, "");
  if (!base) return null;
  const http = base.replace(/^wss:/i, "https:").replace(/^ws:/i, "http:");
  return /^https?:/i.test(http) ? http : null;
}
function codeUrl(relay, code) {
  const http = httpBase(relay);
  return http ? `${http}/code/${code}` : null;
}
function lobbyUrl(relay, docKey, uid, name, pk) {
  const base = relay.trim().replace(/\/+$/, "");
  if (!/^wss?:/i.test(base)) return null;
  const q = new URLSearchParams({ lobby: "1", uid, name, pk });
  return `${base}/subms-yz-${encodeURIComponent(docKey)}?${q.toString()}`;
}
function inviteToPayload(json, now = Date.now()) {
  try {
    const raw = JSON.parse(json);
    if (typeof raw?.exp !== "number" || now > raw.exp) return null;
    const res = decodeShare(encodeShare(raw, { now, ttlMs: raw.exp - now }), now);
    return res.ok ? { ...res.payload, exp: raw.exp } : null;
  } catch {
    return null;
  }
}
var LOBBY_REFUSAL = {
  4001: "The owner has removed you from this share.",
  4003: "That request could not be made. Reload and try again.",
  4004: "The owner has ended this share.",
  4008: "The owner did not let you in.",
  4009: "Too many people are waiting to join. Try again in a moment.",
  4010: "This share is full: it holds 200 people."
};

// editor/collab/access/answerSeal.ts
var ECDH = { name: "ECDH", namedCurve: "P-256" };
var ANSWER_CONTEXT = "subms-answer-v1";
var INVITE_CONTEXT = "subms-invite-v1";
var GRANT_CONTEXT = "subms-grant-v1";
function unb64(s) {
  const bin = atob(s);
  const out = new Uint8Array(new ArrayBuffer(bin.length));
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}
async function aesKey(priv, pub, salt, usage, context) {
  const bits = await crypto.subtle.deriveBits({ name: "ECDH", public: pub }, priv, 256);
  const hkdf = await crypto.subtle.importKey("raw", bits, "HKDF", false, ["deriveKey"]);
  return crypto.subtle.deriveKey(
    { name: "HKDF", hash: "SHA-256", salt, info: new TextEncoder().encode(context) },
    hkdf,
    { name: "AES-GCM", length: 256 },
    false,
    [usage]
  );
}
async function ecdhPrivateKey(signingKey) {
  const pkcs8 = await crypto.subtle.exportKey("pkcs8", signingKey);
  return crypto.subtle.importKey("pkcs8", pkcs8, ECDH, false, ["deriveBits"]);
}
async function openAnswer(sealed, myPublicKey, myEcdhKey, context = ANSWER_CONTEXT) {
  const s = sealed;
  const copy2 = s && s.v === 1 && s.to ? s.to[myPublicKey] : void 0;
  if (!copy2) return null;
  try {
    const epkRaw = unb64(copy2.epk);
    const epk = await crypto.subtle.importKey("raw", epkRaw, ECDH, false, []);
    const key2 = await aesKey(myEcdhKey, epk, epkRaw, "decrypt", context);
    const plain = await crypto.subtle.decrypt({ name: "AES-GCM", iv: unb64(copy2.iv) }, key2, unb64(copy2.ct));
    return new TextDecoder().decode(plain);
  } catch {
    return null;
  }
}

// editor/collab/rooms/controlFrames.ts
var RelayAction = /* @__PURE__ */ ((RelayAction2) => {
  RelayAction2["RegisterCode"] = "registerCode";
  RelayAction2["SetInviteOnly"] = "setInviteOnly";
  RelayAction2["SetDeadline"] = "setDeadline";
  RelayAction2["Admit"] = "admit";
  RelayAction2["Deny"] = "deny";
  RelayAction2["AdmitLobby"] = "admitLobby";
  RelayAction2["DenyLobby"] = "denyLobby";
  RelayAction2["Kick"] = "kick";
  RelayAction2["Unkick"] = "unkick";
  RelayAction2["EndShare"] = "endShare";
  RelayAction2["ResumeShare"] = "resumeShare";
  RelayAction2["BlockIp"] = "blockIp";
  RelayAction2["UnblockIp"] = "unblockIp";
  RelayAction2["TransferOwner"] = "transferOwner";
  RelayAction2["Grant"] = "grant";
  RelayAction2["Roster"] = "roster";
  RelayAction2["ProveKey"] = "proveKey";
  RelayAction2["ProveOwner"] = "proveOwner";
  RelayAction2["Challenge"] = "challenge";
  RelayAction2["Evicted"] = "evicted";
  RelayAction2["Waiting"] = "waiting";
  RelayAction2["Admitted"] = "admitted";
  RelayAction2["Invite"] = "invite";
  RelayAction2["Unknown"] = "unknown";
  return RelayAction2;
})(RelayAction || {});
var RELAY_ACTIONS = new Set(Object.values(RelayAction));
var RefusalWhy = /* @__PURE__ */ ((RefusalWhy2) => {
  RefusalWhy2["Transferred"] = "transferred";
  RefusalWhy2["OtherKey"] = "other-key";
  RefusalWhy2["NotOwner"] = "not-owner";
  RefusalWhy2["Unproven"] = "unproven";
  RefusalWhy2["NoKey"] = "no-key";
  RefusalWhy2["BadSignature"] = "bad-signature";
  RefusalWhy2["NoTarget"] = "no-target";
  RefusalWhy2["Taken"] = "taken";
  RefusalWhy2["BadCode"] = "bad-code";
  RefusalWhy2["CodeStore"] = "code-store";
  RefusalWhy2["None"] = "";
  RefusalWhy2["Unknown"] = "unknown";
  return RefusalWhy2;
})(RefusalWhy || {});
var REFUSAL_WHYS = new Set(Object.values(RefusalWhy));
async function signOwnerNonce(privateKey, nonce) {
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, privateKey, new TextEncoder().encode(`subms-owner:${nonce}`));
  let bin = "";
  for (const b of new Uint8Array(sig)) bin += String.fromCharCode(b);
  return btoa(bin);
}
async function signKeyNonce(privateKey, nonce) {
  const sig = await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, privateKey, new TextEncoder().encode(`subms-key:${nonce}`));
  let bin = "";
  for (const b of new Uint8Array(sig)) bin += String.fromCharCode(b);
  return btoa(bin);
}

// editor/collab/agents/suggestions.ts
var TEXT = "content";
function map2(doc) {
  return doc.getMap(SUGGESTIONS);
}
function newSuggestionId() {
  return `s_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 7)}`;
}
function suggestText(doc, range, after, by, extra = {}) {
  const text = doc.getText(TEXT);
  const s = {
    id: extra.id ?? newSuggestionId(),
    by,
    // Start sticks right and end sticks left, so text typed at either edge
    // stays outside the span.
    from: relativePositionToJSON(createRelativePositionFromTypeIndex(text, range.from, 0)),
    to: relativePositionToJSON(createRelativePositionFromTypeIndex(text, range.to, -1)),
    before: text.toString().slice(range.from, range.to),
    after,
    status: "open" /* Open */,
    at: Date.now(),
    ...extra.why ? { why: extra.why } : {},
    ...extra.runId ? { runId: extra.runId } : {}
  };
  map2(doc).set(s.id, s);
  return s;
}

// ../../packages/identity/src/runes.ts
var VALKYRIE_RUNES = [
  { id: "fehu", name: "Fehu", meaning: "Wealth / Abundance", path: "M9 3V21M9 9L16 4M9 14L16 9" },
  { id: "uruz", name: "Uruz", meaning: "Primal Strength", path: "M8 21V3L16 9V21" },
  { id: "thurisaz", name: "Thurisaz", meaning: "Giants / Force", path: "M9 3V21M9 8L15 12L9 16" },
  { id: "ansuz", name: "Ansuz", meaning: "Wisdom / Voice", path: "M9 3V21M9 4L15 9M9 10L15 15" },
  { id: "raidho", name: "Raidho", meaning: "Journey / Progress", path: "M9 3V21M9 3L15 7.5L9 12L15 21" },
  { id: "kenaz", name: "Kenaz", meaning: "Torch / Focus", path: "M15 4L9 12L15 20" },
  { id: "gebo", name: "Gebo", meaning: "Gift / Exchange", path: "M6 4L18 20M18 4L6 20" },
  { id: "wunjo", name: "Wunjo", meaning: "Joy / Harmony", path: "M9 3V21M9 3L15 7.5L9 12" },
  { id: "hagalaz", name: "Hagalaz", meaning: "Disruption / Chaos", path: "M8 3V21M16 3V21M8 9L16 15" },
  { id: "naudiz", name: "Naudiz", meaning: "Necessity / Drive", path: "M12 3V21M8 9L16 14" },
  { id: "isaz", name: "Isaz", meaning: "Ice / Preservation", path: "M12 3V21" },
  { id: "jera", name: "Jera", meaning: "Harvest / Cycles", path: "M11 5L7 10L11 15M13 9L17 14L13 19" },
  { id: "eihwaz", name: "Eihwaz", meaning: "Endurance / Yew Tree", path: "M12 3V21M12 3L16 7M12 21L8 17" },
  { id: "perthro", name: "Perthro", meaning: "Mystery / Probability", path: "M8 3V21M8 3L13 7L15 4M8 21L13 17L15 20" },
  { id: "algiz", name: "Algiz", meaning: "Protection / Shield", path: "M12 3V21M12 10L7 4M12 10L17 4" },
  { id: "sowilo", name: "Sowilo", meaning: "Sun / Energy", path: "M15 3L9 9L15 15L9 21" },
  { id: "tiwaz", name: "Tiwaz", meaning: "Justice / Victory", path: "M12 3V21M6 9L12 3L18 9" },
  { id: "berkano", name: "Berkano", meaning: "Growth / New Birth", path: "M8 3V21M8 3L15 7.5L8 12L15 16.5L8 21" },
  { id: "ehwaz", name: "Ehwaz", meaning: "Trust / Teamwork", path: "M7 3V21M17 3V21M7 3L12 9L17 3" },
  { id: "mannaz", name: "Mannaz", meaning: "Human / Self", path: "M7 3V21M17 3V21M7 3L17 11M17 3L7 11" },
  { id: "laguz", name: "Laguz", meaning: "Water / Flow / Intuition", path: "M9 3V21M9 3L15 9" },
  { id: "ingwaz", name: "Ingwaz", meaning: "Seed / Internal Growth", path: "M12 4L18 12L12 20L6 12Z" },
  { id: "dagaz", name: "Dagaz", meaning: "Day / Dawn / Breakthrough", path: "M6 4V20M18 4V20M6 4L18 20M18 4L6 20" },
  { id: "othala", name: "Othala", meaning: "Ancestral Land / Heritage", path: "M12 3L17 9L12 15L7 9ZM9 12.5L5 21M15 12.5L19 21" },
  // The Younger Futhark after the Elder: its own staves and twigs, drawn so no
  // two agents share a face even where the names are cousins (naud, naudiz).
  { id: "kaun", name: "Kaun", meaning: "Ulcer / Fire / Transmutation", alphabet: "younger", path: "M12 3V21M12 9L17 4" },
  { id: "hagall", name: "Hagall", meaning: "Hail / Structural Storm", alphabet: "younger", path: "M12 3V21M6 6L18 18M18 6L6 18" },
  { id: "naud", name: "Naud", meaning: "Constraints / Necessity", alphabet: "younger", path: "M12 3V21M7 13L17 9" },
  { id: "is", name: "Is", meaning: "Ice / Absolute Zero", alphabet: "younger", path: "M12 3V21M10 3H14M10 21H14" },
  { id: "ar", name: "Ar", meaning: "Plenty / Good Year", alphabet: "younger", path: "M12 3V21M12 12L17 9" },
  { id: "sol", name: "Sol", meaning: "Sun / Vital Power", alphabet: "younger", path: "M9 3L15 9L9 15L15 21" },
  { id: "tyr", name: "Tyr", meaning: "The Sky God / Leadership", alphabet: "younger", path: "M12 3V21M12 3L7 8" },
  { id: "bjarkan", name: "Bjarkan", meaning: "Birch / Renewal", alphabet: "younger", path: "M9 3V21M9 3L14 7.5L9 12L14 16.5L9 21" },
  { id: "madr", name: "Madr", meaning: "Man / Human Element", alphabet: "younger", path: "M12 3V21M12 9L7 3.5M12 9L17 3.5" },
  { id: "logr", name: "Logr", meaning: "Water / Deep Oceans", alphabet: "younger", path: "M10 3V21M10 3L16 8" },
  { id: "yr", name: "Yr", meaning: "Yew / Bow / Precision", alphabet: "younger", path: "M12 3V21M12 14L7 20M12 14L17 20" },
  { id: "os", name: "Os", meaning: "Mouth / Divine Voice", alphabet: "younger", path: "M10 3V21M10 7L16 11M10 12L16 16" },
  { id: "stong", name: "Stunginn Iss", meaning: "Punctured Ice / Stealth", alphabet: "younger", path: "M12 3V21M9 12H15" },
  { id: "sol-v2", name: "Sol (Alternative)", meaning: "Radiance", alphabet: "younger", path: "M12 4V20M4 12H20M6.5 6.5L17.5 17.5M17.5 6.5L6.5 17.5" },
  { id: "thurs", name: "Thurs", meaning: "Giant Force", alphabet: "younger", path: "M10 3V21M10 7L16 12L10 17" },
  { id: "reidh", name: "Reidh", meaning: "Riding / Active Transit", alphabet: "younger", path: "M10 3V21M10 3L16 7L10 11L16 21" }
];
var AGENT_HANDLE_PREFIX = "agent-valkyrie-";
function valkyrieHandle(i) {
  const n = Math.max(0, Math.floor(i));
  const rune = VALKYRIE_RUNES[n % VALKYRIE_RUNES.length];
  const round = Math.floor(n / VALKYRIE_RUNES.length);
  return `${AGENT_HANDLE_PREFIX}${rune.id}${round ? `-${round + 1}` : ""}`;
}

// editor/collab/mentions/mentionTargets.ts
var MentionGroup = /* @__PURE__ */ ((MentionGroup2) => {
  MentionGroup2["AgentsAll"] = "agent-valkyrie-all";
  MentionGroup2["Agents"] = "agents";
  MentionGroup2["All"] = "all";
  MentionGroup2["LegacyAgentsAll"] = "Agent-Smith-All";
  return MentionGroup2;
})(MentionGroup || {});
function agentHandle(i) {
  return valkyrieHandle(i);
}
function mentionHandle(name) {
  return name.trim().replace(/@/g, "").replace(/\s+/g, "-");
}
var key = (handle) => mentionHandle(handle).toLowerCase();
function parseMentions(body) {
  const out = [];
  const seen = /* @__PURE__ */ new Set();
  for (const m of body.matchAll(/(^|[^\w@])@([^\s@]+)/g)) {
    const h = m[2].replace(/[.,!?;:)\]}'"]+$/, "");
    if (!h || seen.has(h.toLowerCase())) continue;
    seen.add(h.toLowerCase());
    out.push(h);
  }
  return out;
}
function toMentionGroup(handle) {
  const k = key(handle);
  return Object.values(MentionGroup).find((g) => g.toLowerCase() === k);
}
function addressingOf(body) {
  const to = [];
  let agents = false;
  let everyone = false;
  for (const h of parseMentions(body)) {
    const g = toMentionGroup(h);
    if (g === "all" /* All */) everyone = true;
    else if (g) agents = true;
    else to.push(h);
  }
  return { to, agents, everyone };
}
function isAddressedTo(a, name, isAgent) {
  if (a.everyone || isAgent && a.agents) return true;
  const k = key(name);
  return a.to.some((h) => key(h) === k);
}
function namesAnyone(a) {
  return a.everyone || a.agents || a.to.length > 0;
}

// ../../packages/deltagraph/src/board/palette.ts
var DG_COLORS = {
  // Canvas
  canvasBackground: "#0f1115",
  // board backdrop (dark theme)
  // Element default stroke, before a shape-specific accent is applied
  elementDefault: "#e6e6e6",
  // Per-shape accent strokes (new element defaults)
  rectangleStroke: "#4c8dff",
  // blue
  ellipseStroke: "#7ad9a7",
  // green
  diamondStroke: "#ffce4d",
  // amber
  frameStroke: "#3a4152",
  // muted slate (frames are chrome, not content)
  groupStroke: "#8b7ff0",
  // soft violet - grouping containers, distinct from frame chrome
  connectorStroke: "#8892a6",
  // arrows / lines: neutral grey
  // Sticky note
  stickyFill: "#ffe066",
  // classic yellow
  stickyStroke: "#3a340f",
  // dark text/border on the yellow
  // Connector emphasis (DSL-driven edges)
  edgeTrigger: "#ff9f43"
  // a "full recompute" / eager-trigger edge stands out orange
};

// ../../packages/deltagraph/src/board/schema.ts
var DgFormat = {
  /** Pre-rename spelling. READ ONLY - accepted so an older saved board opens,
   *  never written, and not part of the current lineage. */
  WhiteboardV1: "whiteboard/v1",
  DeltagraphV1: "deltagraph/v1"
};
var DG_FORMAT = DgFormat.DeltagraphV1;
var DG_FORMATS_READABLE = [
  DgFormat.DeltagraphV1,
  DgFormat.WhiteboardV1
];
var DgLayoutDirection = {
  Auto: "auto",
  TopDown: "top_down",
  BottomTop: "bottom_top",
  LeftRight: "left_right",
  RightLeft: "right_left"
};
var DIRECTION_ALIASES = {
  auto: DgLayoutDirection.Auto,
  tb: DgLayoutDirection.TopDown,
  td: DgLayoutDirection.TopDown,
  top_down: DgLayoutDirection.TopDown,
  "top-down": DgLayoutDirection.TopDown,
  bt: DgLayoutDirection.BottomTop,
  bottom_top: DgLayoutDirection.BottomTop,
  "bottom-top": DgLayoutDirection.BottomTop,
  lr: DgLayoutDirection.LeftRight,
  left_right: DgLayoutDirection.LeftRight,
  "left-right": DgLayoutDirection.LeftRight,
  rl: DgLayoutDirection.RightLeft,
  right_left: DgLayoutDirection.RightLeft,
  "right-left": DgLayoutDirection.RightLeft
};
var DgElementType = {
  Rectangle: "rectangle",
  Ellipse: "ellipse",
  Diamond: "diamond",
  Line: "line",
  Arrow: "arrow",
  Freedraw: "freedraw",
  Text: "text",
  Sticky: "sticky",
  Image: "image",
  /** A live web page, by URL in `data.src`.
   *
   *  The one element the board cannot RASTERISE: an iframe is a browser
   *  context, not pixels, so it renders as a labelled placeholder in the SVG and
   *  as a real frame in a DOM overlay above it. That split is why it is its own
   *  type rather than a Rectangle with a URL on it - every export path has to
   *  know it cannot draw this, and a type is how they find out. */
  Embed: "embed",
  Frame: "frame",
  Group: "group",
  /** ONE diagram on a board. A board holds many, of different kinds, and a
   *  markdown fence is the degenerate case of exactly one.
   *
   *  It carries the semantic MODEL; its child elements are a projection of that
   *  model, linked by `parent`. Editing a diagram means editing its model and
   *  re-projecting, which is what keeps a sequence diagram's time ordering
   *  correct no matter how it is dragged.
   *
   *  Distinct from Frame (a hand-drawn artboard that may CONTAIN several
   *  diagrams) and Zone (a subgraph container INSIDE one diagram). */
  Diagram: "diagram",
  /** A block of markdown prose, source in `data.md`.
   *
   *  Like Embed, it is drawn in a DOM overlay through the site's markdown
   *  pipeline (tables, code, math, links), and as a labelled box in SVG export.
   *  It exists so prose can sit on a board beside diagrams and graphics -
   *  imported HTML keeps its text instead of losing it. */
  Markdown: "markdown",
  /** A block of source code, text in `data.code`, language id in `data.lang`,
   *  an optional file name in `data.name` (a dropped file keeps its name).
   *
   *  Drawn like Markdown: the SVG holds the card, a DOM overlay runs the real
   *  code editor so highlighting and editing are the editor's own. Export
   *  carries the card and the text in a monospace face. */
  Code: "code",
  /** A video clip held as an asset (`assetId`, a `video/*` data URL). The SVG
   *  cannot play it, so it draws a poster-less frame and a DOM overlay hosts the
   *  real <video>. An animated GIF stays an Image; the overlay plays it. */
  Video: "video",
  /** A spreadsheet: `data.cols` x `data.rows` cells keyed A1-style in
   *  `data.cells` (raw text, a leading "=" is a formula, evaluated by
   *  `board/sheet.ts`). The SVG draws headers, rules and evaluated values, so an
   *  export shows numbers; a DOM overlay is the editor. */
  Grid: "grid",
  /** A runnable notebook cell: `data.code` (Python), `data.output` (the last
   *  run's text), `data.error`. The kernel is the notebook package's Pyodide
   *  runtime; the SVG shows the code and the last output. */
  Notebook: "notebook",
  // A small project: a file tree, an editor and a run bar in one frame.
  Workspace: "workspace",
  // A live poll and a shared countdown: facilitation blocks.
  Poll: "poll",
  Timer: "timer",
  /** A subgraph container: a labelled zone grouping related nodes (mermaid
   *  `subgraph` blocks and DSL `subgraph`/`group` blocks render as these).
   *  Derived + fitted to its members after layout - it doesn't own or arrange
   *  them. Pairs with, but is distinct from, Frame (a hand-DRAWN artboard that
   *  owns + auto-arranges its children) and Group (a multi-select). */
  Zone: "zone"
};
var DG_ELEMENT_TYPES = new Set(Object.values(DgElementType));
var DgFillStyle = { Solid: "solid", Hachure: "hachure", Transparent: "transparent" };
var DgStrokeStyle = { Solid: "solid", Dashed: "dashed", Dotted: "dotted" };
var DgFontFamily = { Hand: "hand", Sans: "sans", Mono: "mono", Serif: "serif" };
var DgAlign = { Left: "left", Center: "center", Right: "right" };
var DgArrowhead = { Triangle: "triangle" };
var DgErCardinality = {
  ZeroOrOne: "zero_or_one",
  ExactlyOne: "exactly_one",
  ZeroOrMany: "zero_or_many",
  OneOrMany: "one_or_many"
};
var ER_CARDINALITIES = new Set(Object.values(DgErCardinality));

// ../../packages/deltagraph/src/board/fracIndex.ts
var Z_WIDTH = 12;
var Z_STEP = 1e6;
function zStr(n) {
  const clamped = Math.max(0, Math.min(10 ** Z_WIDTH - 1, Math.round(n)));
  return String(clamped).padStart(Z_WIDTH, "0");
}
function zNum(z) {
  const n = parseInt(z, 10);
  return Number.isFinite(n) ? n : 0;
}
function zTop(zs) {
  let max2 = 0;
  for (const z of zs) max2 = Math.max(max2, zNum(z));
  return zStr(max2 + Z_STEP);
}

// ../../packages/deltagraph/src/board/model.ts
var idCounter = 0;
function newElementId() {
  idCounter = (idCounter + 1) % 1e9;
  return `el_${Date.now().toString(36)}${idCounter.toString(36)}`;
}
function newSeed() {
  return Math.floor(Math.random() * 2 ** 31);
}
var HOLLOW_TYPES = /* @__PURE__ */ new Set([
  DgElementType.Rectangle,
  DgElementType.Ellipse,
  DgElementType.Diamond,
  DgElementType.Zone
]);
function makeElement(type, x, y, w, h, zs, by) {
  const base = {
    id: newElementId(),
    type,
    x,
    y,
    w,
    h,
    z: zTop(zs),
    seed: newSeed(),
    createdBy: by,
    updatedAt: Date.now(),
    version: 1
  };
  const style = { strokeColor: DG_COLORS.elementDefault, strokeWidth: 2, fillStyle: DgFillStyle.Transparent, opacity: 100 };
  switch (type) {
    case DgElementType.Rectangle:
      return { ...base, cornerRadius: 8, style: { ...style, strokeColor: DG_COLORS.rectangleStroke } };
    case DgElementType.Ellipse:
      return { ...base, style: { ...style, strokeColor: DG_COLORS.ellipseStroke } };
    case DgElementType.Diamond:
      return { ...base, style: { ...style, strokeColor: DG_COLORS.diamondStroke } };
    case DgElementType.Frame:
      return { ...base, name: "Frame", style: { strokeColor: DG_COLORS.frameStroke } };
    // Dashed by default, and it stays dashed: the outline is what shows through
    // in an export where the live page cannot.
    case DgElementType.Embed:
      return { ...base, style: { ...style, strokeColor: DG_COLORS.connectorStroke, strokeStyle: DgStrokeStyle.Solid, strokeWidth: 1 } };
    case DgElementType.Code:
      return { ...base, data: { code: "", lang: "typescript" }, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Video:
      return { ...base, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Grid:
      return { ...base, data: { cols: 4, rows: 5, cells: {} }, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Notebook:
      return { ...base, data: { code: "", lang: "python" }, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Workspace:
      return { ...base, data: { files: [], active: "" }, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Poll:
      return { ...base, data: { question: "", options: [], state: "draft", votes: {} }, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Timer:
      return { ...base, data: { label: "", durationMs: 3e5 }, style: { ...style, strokeColor: DG_COLORS.connectorStroke } };
    case DgElementType.Arrow:
      return { ...base, points: [[0, 0], [w, h]], endArrowhead: DgArrowhead.Triangle, style: { strokeColor: DG_COLORS.connectorStroke, strokeWidth: 2 } };
    case DgElementType.Line:
      return { ...base, points: [[0, 0], [w, h]], style: { strokeColor: DG_COLORS.connectorStroke, strokeWidth: 2 } };
    case DgElementType.Freedraw:
      return { ...base, ink: [], style: { ...style } };
    case DgElementType.Text:
      return { ...base, text: "", align: DgAlign.Left, style: { ...style, fontSize: 20 } };
    case DgElementType.Sticky:
      return { ...base, text: "", align: DgAlign.Center, style: { backgroundColor: DG_COLORS.stickyFill, strokeColor: DG_COLORS.stickyStroke, fontFamily: DgFontFamily.Hand, fontSize: 13 } };
    default:
      return { ...base, style };
  }
}
function elementAabb(el) {
  const x = Math.min(el.x, el.x + el.w);
  const y = Math.min(el.y, el.y + el.h);
  return { x, y, w: Math.abs(el.w), h: Math.abs(el.h) };
}

// editor/body/whiteboard-v1/boardCrdt.ts
var jsonEq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function elementsFromY(yEls) {
  return [...yEls.values()].map(elFromY).filter((e) => !!e).sort((a, b) => {
    const az = String(a.z ?? ""), bz = String(b.z ?? "");
    return az < bz ? -1 : az > bz ? 1 : String(a.id).localeCompare(String(b.id));
  });
}
function elFromY(v) {
  if (!(v instanceof YMap)) return v ?? null;
  if (typeof v.get("id") !== "string") return null;
  const out = {};
  let votes = null;
  let data = null;
  let style = null;
  const entries = {};
  let fileOrder = null;
  const fileBodies = /* @__PURE__ */ new Map();
  for (const [k, x] of v.entries()) {
    if (k.startsWith(VOTE_KEY)) {
      if (typeof x === "number" && x > 0) (votes ??= {})[k.slice(VOTE_KEY.length)] = x;
      continue;
    }
    if (k.startsWith(FILE_KEY)) {
      fileBodies.set(k.slice(FILE_KEY.length), typeof x === "string" ? x : String(x ?? ""));
      continue;
    }
    if (k === FILE_ORDER) {
      if (Array.isArray(x)) fileOrder = x.filter((p) => typeof p === "string");
      continue;
    }
    if (k.startsWith(DATA)) {
      const rest = k.slice(DATA.length);
      const dot = rest.indexOf(".");
      const name = dot < 0 ? rest : rest.slice(0, dot);
      if (dot >= 0 && ENTRY_MAPS.has(name)) (entries[name] ??= {})[rest.slice(dot + 1)] = x;
      else (data ??= {})[rest] = x;
      continue;
    }
    if (k === "text" && x instanceof YText) {
      out.text = x.toString();
      continue;
    }
    if (k.startsWith(STYLE)) {
      (style ??= {})[k.slice(STYLE.length)] = x;
      continue;
    }
    out[k] = x;
  }
  if (votes) out.votes = votes;
  if (data || Object.keys(entries).length || fileOrder) {
    const d = { ...isPlain(out.data) ? out.data : {}, ...data ?? {} };
    for (const [name, m] of Object.entries(entries)) d[name] = { ...isPlain(d[name]) ? d[name] : {}, ...m };
    if (fileOrder) {
      const order = [...fileOrder.filter((p) => fileBodies.has(p)), ...[...fileBodies.keys()].filter((p) => !fileOrder.includes(p))];
      d.files = order.map((path) => ({ path, content: fileBodies.get(path) }));
    }
    out.data = d;
  }
  if (style) out.style = { ...isPlain(out.style) ? out.style : {}, ...style };
  return out;
}
var VOTE_KEY = "vote.";
var DATA = "data.";
var STYLE = "style.";
var ENTRY_MAPS = /* @__PURE__ */ new Set(["votes", "names", "cells"]);
var FILE_ORDER = "data.files";
var FILE_KEY = "file.";
var isFileList = (v) => Array.isArray(v) && v.every((f) => isPlain(f) && typeof f.path === "string" && typeof f.content === "string");
var isPlain = (v) => !!v && typeof v === "object" && !Array.isArray(v);
function writeElToY(yEls, el) {
  const doc = yEls.doc;
  if (doc) doc.transact(() => writeEl(yEls, el));
  else writeEl(yEls, el);
}
function writeEl(yEls, el) {
  let m = yEls.get(el.id);
  if (!(m instanceof YMap)) {
    m = new YMap();
    yEls.set(el.id, m);
  }
  const em = m;
  const { votes, data, style, text, ...plain } = el;
  if (typeof text === "string") {
    const cur = em.get("text");
    if (cur instanceof YText) applyTextDiff(cur, text);
    else {
      const t = new YText();
      t.insert(0, text);
      em.set("text", t);
    }
  } else if (text !== void 0) plain.text = text;
  const want = /* @__PURE__ */ new Map();
  for (const [k, v] of Object.entries(plain)) if (v !== void 0) want.set(k, v);
  for (const [uid, n] of Object.entries(votes ?? {})) if (n > 0) want.set(VOTE_KEY + uid, n);
  if (isPlain(data)) {
    for (const [k, v] of Object.entries(data)) {
      if (v === void 0) continue;
      if (k === "files" && isFileList(v)) {
        want.set(FILE_ORDER, v.map((f) => f.path));
        for (const f of v) want.set(FILE_KEY + f.path, f.content);
        continue;
      }
      if (ENTRY_MAPS.has(k) && isPlain(v)) {
        want.set(DATA + k, {});
        for (const [ek, ev] of Object.entries(v)) if (ev !== void 0) want.set(`${DATA}${k}.${ek}`, ev);
      } else want.set(DATA + k, v);
    }
  } else if (data !== void 0) want.set("data", data);
  if (isPlain(style)) {
    for (const [k, v] of Object.entries(style)) if (v !== void 0) want.set(STYLE + k, v);
  } else if (style !== void 0) want.set("style", style);
  for (const [k, v] of want) if (!jsonEq(em.get(k), v)) em.set(k, v);
  for (const k of [...em.keys()]) if (!want.has(k) && !(k === "text" && typeof text === "string")) em.delete(k);
}
function applyTextDiff(t, next) {
  const cur = t.toString();
  if (cur === next) return;
  let start = 0;
  const max2 = Math.min(cur.length, next.length);
  while (start < max2 && cur.charCodeAt(start) === next.charCodeAt(start)) start++;
  let endCur = cur.length, endNext = next.length;
  while (endCur > start && endNext > start && cur.charCodeAt(endCur - 1) === next.charCodeAt(endNext - 1)) {
    endCur--;
    endNext--;
  }
  const high = (c) => c >= 55296 && c <= 56319;
  const low = (c) => c >= 56320 && c <= 57343;
  if (start > 0 && high(cur.charCodeAt(start - 1))) start--;
  if (endCur < cur.length && low(cur.charCodeAt(endCur))) {
    endCur++;
    endNext++;
  }
  if (endCur > start) t.delete(start, endCur - start);
  if (endNext > start) t.insert(start, next.slice(start, endNext));
}

// ../../packages/deltaboard/src/boardComments.ts
var BOARD_THREAD_ID = "__board__";

// agent/boardService.ts
var DG_BOARD_HOST = typeof process !== "undefined" && process.env?.DELTALAB_DG_HOST?.trim() || "https://deltagraph.submillisecond.com";
async function remote(req) {
  const res = await fetch(`${DG_BOARD_HOST.replace(/\/+$/, "")}/board`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(req)
  });
  if (!res.ok) throw new Error(`the deltagraph worker answered ${res.status}: ${(await res.text()).slice(0, 160)}`);
  return await res.json();
}
var service = remote;
function boardService() {
  return service;
}

// ../../packages/deltagraph/src/text/link.ts
var DG_FRAGMENT_KEY = "d1";
var toB64Url = (bytes) => {
  let s = "";
  for (let i = 0; i < bytes.length; i += 32768) {
    s += String.fromCharCode(...bytes.subarray(i, i + 32768));
  }
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};
var fromB64Url = (s) => {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/");
  const bin = atob(b64 + "=".repeat((4 - b64.length % 4) % 4));
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
};
async function pipe(data, mode) {
  const stream = mode === "deflate-raw" ? new CompressionStream("deflate-raw") : new DecompressionStream("deflate-raw");
  const buf = await new Response(new Blob([data]).stream().pipeThrough(stream)).arrayBuffer();
  return new Uint8Array(buf);
}
async function encodeDsl(dsl) {
  return toB64Url(await pipe(new TextEncoder().encode(dsl), "deflate-raw"));
}
async function decodeDsl(packed) {
  try {
    return new TextDecoder().decode(await pipe(fromB64Url(packed), "inflate-raw"));
  } catch {
    return null;
  }
}
async function deltagraphHref(dsl, base = "/deltagraph", opts = {}) {
  return `${base}#${DG_FRAGMENT_KEY}=${await encodeDsl(dsl)}${optionsSuffix(opts)}`;
}
var DG_PLAIN_KEY = "dsl";
function fragmentValue(hash, key2) {
  const cut = hash.indexOf("#");
  const h = cut >= 0 ? hash.slice(cut + 1) : hash;
  for (const part of h.split("&")) {
    const eq = part.indexOf("=");
    if (eq > 0 && part.slice(0, eq) === key2) return part.slice(eq + 1);
  }
  return null;
}
function packedFromHash(hash) {
  return fragmentValue(hash, DG_FRAGMENT_KEY);
}
async function dslFromHash(hash) {
  const packed = packedFromHash(hash);
  if (packed) return decodeDsl(packed);
  const plain = fragmentValue(hash, DG_PLAIN_KEY);
  if (plain == null) return null;
  return decodePlain(plain);
}
function decodePlain(raw) {
  return raw.replace(/(%[0-9A-Fa-f]{2})+|%/g, (m) => {
    if (m === "%") return "%";
    try {
      return decodeURIComponent(m);
    } catch {
      return m;
    }
  });
}
var DgLinkOption = {
  Title: "title",
  Theme: "theme",
  Dir: "dir",
  Debug: "debug",
  Edit: "edit",
  Bg: "bg",
  Embed: "embed"
};
var DG_HISTORY_KEY = "h";
function bgParam(bg) {
  return bg.startsWith("#") ? bg.slice(1) : bg;
}
function optionsSuffix(opts) {
  const parts = [];
  if (opts.title) parts.push(`${DgLinkOption.Title}=${encodeURIComponent(opts.title)}`);
  if (opts.theme) parts.push(`${DgLinkOption.Theme}=${opts.theme}`);
  if (opts.bg) parts.push(`${DgLinkOption.Bg}=${bgParam(opts.bg)}`);
  if (opts.dir) parts.push(`${DgLinkOption.Dir}=${opts.dir}`);
  if (opts.debug) parts.push(`${DgLinkOption.Debug}=true`);
  if (opts.edit) parts.push(`${DgLinkOption.Edit}=true`);
  if (opts.embed) parts.push(`${DgLinkOption.Embed}=true`);
  if (opts.history?.length) parts.push(`${DG_HISTORY_KEY}=${opts.history.join(",")}`);
  return parts.length ? `&${parts.join("&")}` : "";
}

// agent/participant.ts
var logFn = (line) => console.log(line);
function setAgentLog(fn) {
  logFn = fn;
}
var log = (line) => logFn(line);
function relayFor(link, override) {
  if (override) return override;
  const host = (() => {
    try {
      return new URL(link).hostname;
    } catch {
      return "";
    }
  })();
  if (host.startsWith("beta.")) return "wss://beta.collab.submillisecond.com";
  if (host.endsWith("submillisecond.com")) return "wss://collab.submillisecond.com";
  throw new Error("cannot infer the relay from the link; pass --relay");
}
var COLORS = ["#39c5cf", "#4fa3e8", "#2fb3a3", "#7c9cff", "#5bc0be", "#58a6ff", "#3ddc97"];
function slug(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 20);
}
async function identity(name, i, runBy) {
  const kp = await generateKeyPair();
  const pub = await exportPublicKey(kp.publicKey);
  const id2 = `bot_${slug(name)}_${Math.random().toString(36).slice(2, 7)}`;
  return { name, id: id2, kp, pub, color: COLORS[i % COLORS.length], runBy };
}
function presenceUser(me2) {
  return {
    name: me2.name,
    email: `${me2.id}@agents.submillisecond.com`,
    id: me2.id,
    sessionId: `${me2.id}_s`,
    color: me2.color,
    colorLight: `${me2.color}33`,
    connectedAt: Date.now(),
    pubKey: me2.pub,
    // Every avatar reads this and draws the robot with the agent ring, and
    // the tooltip and roster say who runs it.
    agent: true,
    ...me2.runBy ? { agentFor: me2.runBy } : {}
  };
}
async function joinWith(payload, me2, relay, opts = {}) {
  const doc = new Doc();
  const wireDoc = new Doc();
  const wire = wireDoc.getArray("env");
  const roomKey = payload.roomKey ? await roomKeyFromFragment(payload.roomKey) ?? void 0 : void 0;
  const access = {
    docId: payload.docKey,
    ownerPublicKey: payload.ownerKey ?? "",
    myPublicKey: me2.pub,
    myPrivateKey: me2.kp.privateKey,
    myCapability: payload.cap ?? null,
    me: { id: me2.id, name: me2.name },
    roomKey,
    modes: wireDoc.getArray("mode"),
    // Honour the owner's revocations like a browser does, and let an owner bot
    // issue them.
    revocations: wireDoc.getArray("revoke")
  };
  const bridge = bridgeAuthorizedSync(doc, wire, access, () => log(`${me2.name}: dropped an envelope that did not authorize`));
  const awareness = new Awareness(wireDoc);
  const shown = { ...presenceUser(me2), ...opts.userId ? { id: opts.userId } : {}, ...opts.claimPub ? { pubKey: opts.claimPub } : {} };
  awareness.setLocalStateField("user", shown);
  awareness.setLocalStateField("docClient", doc.clientID);
  const ws = new WebsocketProvider(relay, `subms-yz-${payload.docKey}`, wireDoc, {
    awareness,
    // Name the participant at connect. Without `uid` the relay infers who a
    // socket is from the first awareness client ids it sees on it, and every
    // y-websocket client re-broadcasts other clients' states: ten agents
    // joining in a few seconds got credited with each other's states, and the
    // relay evicted them (4003) when the key they proved did not match.
    params: { ok: payload.ownerKey ?? "", sid: `${me2.id}_s`, uid: shown.id, name: me2.name, ...payload.cap ? {} : { perm: "view" } },
    // Node's built-in WebSocket.
    WebSocketPolyfill: WebSocket
  });
  const control = [];
  answerChallenges(ws, me2, !!opts.owner, control, (blob) => void acceptGrant(blob));
  const acceptGrant = async (blob) => {
    const json = await openAnswer(blob, me2.pub, await ecdhPrivateKey(me2.kp.privateKey), GRANT_CONTEXT);
    if (!json) return;
    let cap = null;
    try {
      cap = JSON.parse(json).cap ?? null;
    } catch {
      return;
    }
    if (!cap || cap.cap.subject !== me2.pub || !await verifyCapability(cap, access.ownerPublicKey, access.docId)) return;
    access.myCapability = cap;
    hubAw.setLocalStateField("perm", hubPerm());
    log(`${me2.name}: the owner granted ${cap.cap.permission}`);
  };
  ws.on("status", (e) => log(`${me2.name}: ${e.status}`));
  const closes = [];
  ws.on("connection-close", (e) => {
    if (e && e.code >= 4e3) {
      closes.push(e.code);
      log(`${me2.name}: refused ${e.code} ${e.reason}`);
    }
  });
  const hubDoc = new Doc();
  const hubAw = new Awareness(hubDoc);
  hubAw.setLocalState({ user: presenceUser(me2), docKey: payload.docKey, perm: opts.owner ? "owner" : payload.cap ? "editor" : "viewer", viewFrac: null, ping: Date.now() });
  const hub = new WebsocketProvider(relay, "subms-y-presence", hubDoc, {
    awareness: hubAw,
    WebSocketPolyfill: WebSocket
  });
  const beat = setInterval(() => {
    hubAw.setLocalStateField("ping", Date.now());
    awareness.setLocalStateField("user", presenceUser(me2));
  }, 15e3);
  beat.unref();
  doc.getMap("file.meta").observe(() => {
    const t = doc.getMap("file.meta").get("type");
    if (t) log(`${me2.name}: the owner changed the type to ${t.kind} (${t.filename})`);
  });
  const permission = () => {
    const cap = access.myCapability;
    if (!cap || bridge.isRevoked(me2.pub, cap.sig)) return "view";
    const p = cap.cap.permission;
    if (p === "suggest") return "suggest";
    if (p !== "edit") return "view";
    return bridge.docMode() === "review" ? "suggest" : "edit";
  };
  const hubPerm = () => opts.owner ? "owner" : permission() === "edit" ? "editor" : permission() === "suggest" ? "reviewer" : "viewer";
  hubAw.setLocalStateField("perm", hubPerm());
  bridge.onDocMode(() => {
    hubAw.setLocalStateField("perm", hubPerm());
    log(`${me2.name}: the document is now in ${bridge.docMode() === "review" ? "Review: my changes become suggestions" : "Edit"}`);
  });
  const bot = {
    name: me2.name,
    id: me2.id,
    color: me2.color,
    kind: payload.kind,
    doc,
    text: doc.getText("content"),
    els: doc.getMap("wb.elements"),
    comments: doc.getMap("wb.comments"),
    awareness,
    ws,
    hubAw,
    closes,
    control,
    permission,
    revokeAuthor: opts.owner ? async (author) => {
      const list = await Promise.all([...bridge.usage(author)].map(([capSig, n]) => issueRevocation(me2.kp.privateKey, payload.docKey, author, capSig, n)));
      if (list.length) access.revocations.push(list);
      return list.length;
    } : void 0,
    leave: () => {
      clearInterval(beat);
      stopWorking(bot);
      try {
        awareness.setLocalState(null);
        hubAw.setLocalState(null);
      } catch {
      }
      setTimeout(() => {
        ws.destroy();
        hub.destroy();
      }, 300).unref();
    }
  };
  if (!isBoard(bot)) setTimeout(() => park(bot), 3e3).unref();
  return bot;
}
function answerChallenges(ws, me2, owner, control, onGrant) {
  const handlers = ws.messageHandlers;
  const stock = handlers[3];
  handlers[3] = (encoder, decoder, ...rest) => {
    const d = decoder;
    const tail = d.arr.subarray(d.pos);
    let msg = null;
    if (tail[0] === 123) {
      try {
        msg = JSON.parse(new TextDecoder().decode(tail));
      } catch {
        msg = null;
      }
    }
    if (!msg) {
      stock?.(encoder, decoder, ...rest);
      return;
    }
    d.pos = d.arr.length;
    control.push(msg);
    const ev = msg;
    if (ev.action === "evicted" /* Evicted */ && typeof ev.code === "number") {
      try {
        ws.disconnect();
      } catch {
      }
      ws.emit("connection-close", [{ code: ev.code, reason: "evicted" }, ws]);
      return;
    }
    if (msg.action === "grant" /* Grant */ && "blob" in msg) {
      onGrant(msg.blob);
      return;
    }
    if (msg.action !== "challenge" /* Challenge */ || !msg.nonce) return;
    const nonce = msg.nonce;
    void signKeyNonce(me2.kp.privateKey, nonce).then((sig) => sendRaw(ws, { action: "proveKey" /* ProveKey */, pub: me2.pub, sig }));
    if (owner) void signOwnerNonce(me2.kp.privateKey, nonce).then((sig) => sendRaw(ws, { action: "proveOwner" /* ProveOwner */, sig }));
  };
}
function sendRaw(ws, obj) {
  const raw = ws.ws;
  if (!raw || raw.readyState !== 1) return false;
  const json = new TextEncoder().encode(JSON.stringify(obj));
  const out = new Uint8Array(json.length + 1);
  out[0] = 3;
  out.set(json, 1);
  raw.send(out);
  return true;
}
async function knockFor(code, me2, relay) {
  const url = codeUrl(relay, code);
  if (!url) throw new Error("bad relay");
  const res = await fetch(url);
  if (!res.ok) throw new Error(`no live share has code ${code}`);
  const { docKey } = await res.json();
  const lurl = lobbyUrl(relay, docKey, me2.id, me2.name, me2.pub);
  if (!lurl) throw new Error("bad relay");
  const ecdh = await ecdhPrivateKey(me2.kp.privateKey);
  log(`${me2.name}: waiting in the lobby for the owner to admit`);
  return new Promise((resolve, reject) => {
    const sock = new WebSocket(lurl);
    sock.binaryType = "arraybuffer";
    sock.onmessage = (e) => {
      const b = new Uint8Array(e.data);
      if (b[0] !== 3) return;
      let m;
      try {
        m = JSON.parse(new TextDecoder().decode(b.subarray(1)));
      } catch {
        return;
      }
      if (m.action === "evicted" /* Evicted */) {
        sock.close();
        reject(new Error(LOBBY_REFUSAL[m.code ?? 0] ?? "refused"));
      }
      if (m.action !== "invite" /* Invite */) return;
      void openAnswer(m.blob, me2.pub, ecdh, INVITE_CONTEXT).then((json) => {
        sock.close();
        const p = json ? inviteToPayload(json) : null;
        if (p) resolve(p);
        else reject(new Error("could not open the invite"));
      });
    };
    sock.onclose = (e) => {
      if (e.code >= 4e3) reject(new Error(LOBBY_REFUSAL[e.code] ?? `closed ${e.code}`));
    };
  });
}
var sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function showCursor(b, index) {
  const rel = createRelativePositionFromTypeIndex(b.text, index);
  b.awareness.setLocalStateField("cursor", { anchor: rel, head: rel });
}
function lineEnd(t, line) {
  const s = t.toString();
  let idx = 0;
  for (let l = 1; l < line; l++) {
    const nl2 = s.indexOf("\n", idx);
    if (nl2 < 0) return s.length;
    idx = nl2 + 1;
  }
  const nl = s.indexOf("\n", idx);
  return nl < 0 ? s.length : nl;
}
function mayWrite(b, what) {
  const p = b.permission();
  if (p === "edit") return true;
  log(`${b.name}: not writing (${what}): ${p === "suggest" ? "the document is in Review for me, use suggest" : "view only"}`);
  return false;
}
async function typeAt(b, index, text) {
  if (!mayWrite(b, "type")) return typeof index === "number" ? createRelativePositionFromTypeIndex(b.text, index) : index;
  const rel = typeof index === "number" ? createRelativePositionFromTypeIndex(b.text, index, -1) : index;
  const resolve = () => createAbsolutePositionFromRelativePosition(rel, b.doc)?.index ?? null;
  for (let i = 0; i < 30 && resolve() == null; i++) await sleep(100);
  showCursor(b, resolve() ?? b.text.length);
  await sleep(Math.min(1500, 200 + text.length * 2));
  const at = resolve() ?? b.text.length;
  b.text.insert(at, text);
  const end = at + text.length;
  showCursor(b, end);
  b.hubAw.setLocalStateField("viewFrac", b.text.length ? end / b.text.length : null);
  return createRelativePositionFromTypeIndex(b.text, end, -1);
}
async function appendParagraph(b, body) {
  if (!mayWrite(b, "append")) return false;
  const s = b.text.toString();
  const lead = s.length === 0 || s.endsWith("\n\n") ? "" : s.endsWith("\n") ? "\n" : "\n\n";
  await typeAt(b, s.length, lead + body.replace(/\n*$/, "\n"));
  return true;
}
async function writeUnder(b, heading, body) {
  if (!mayWrite(b, "under")) return false;
  const s = b.text.toString();
  const re = new RegExp(`^#{1,6}\\s+${heading.trim().replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}`, "im");
  const m = re.exec(s);
  if (!m) return null;
  const eol = s.indexOf("\n", m.index);
  const after = eol < 0 ? s.length : eol + 1;
  const next = s.slice(after).search(/^#{1,6}\s/m);
  const pos = next < 0 ? s.length : after + next;
  const lead = s.slice(0, pos).endsWith("\n\n") ? "" : "\n";
  await typeAt(b, pos, `${lead}${body.trim()}

`);
  return true;
}
function outline(b) {
  const out = [];
  let fence = false;
  b.text.toString().split("\n").forEach((l, i) => {
    if (/^\s*(```|~~~)/.test(l)) fence = !fence;
    const m = !fence && /^(#{1,6})\s+(.*)$/.exec(l);
    if (m) out.push({ line: i + 1, level: m[1].length, text: m[2].trim() });
  });
  return out;
}
function park(b) {
  const s = b.text.toString();
  const at = s.lastIndexOf(`${b.name}`);
  const pos = at < 0 ? s.length : at;
  showCursor(b, pos);
  b.hubAw.setLocalStateField("viewFrac", s.length ? pos / s.length : null);
}
function addressFor(name, text) {
  const a = addressingOf(text);
  const to = a.to;
  if (isAddressedTo({ to, agents: false, everyone: false }, name, true)) return { addressed: "you" /* You */, to };
  if (a.agents) return { addressed: "agents" /* Agents */, to };
  if (a.everyone) return { addressed: "everyone" /* Everyone */, to };
  return { addressed: namesAnyone(a) ? "others" /* Others */ : "open" /* Open */, to };
}
var isAsked = (a) => a === "you" /* You */ || a === "agents" /* Agents */ || a === "everyone" /* Everyone */;
var TYPING_REFRESH_MS = 3e3;
var TYPING_GIVE_UP_MS = 9e4;
var typingTimers = /* @__PURE__ */ new WeakMap();
function startWorking(b) {
  stopWorking(b);
  b.hubAw.setLocalStateField("typing", Date.now());
  const beat = setInterval(() => b.hubAw.setLocalStateField("typing", Date.now()), TYPING_REFRESH_MS);
  const stop = setTimeout(() => stopWorking(b), TYPING_GIVE_UP_MS);
  beat.unref();
  stop.unref();
  typingTimers.set(b, { beat, stop });
}
function stopWorking(b) {
  const t = typingTimers.get(b);
  if (t) {
    clearInterval(t.beat);
    clearTimeout(t.stop);
    typingTimers.delete(b);
  }
  try {
    b.hubAw.setLocalStateField("typing", null);
  } catch {
  }
}
function deliver(sink, m) {
  if (typeof sink === "function") sink(m);
  else appendFileSync(sink, JSON.stringify(m) + "\n");
}
function deliverFor(b, sink, m) {
  const a = addressFor(b.name, m.text);
  deliver(sink, { ...m, ...a });
  if (isAsked(a.addressed)) startWorking(b);
}
var threads = /* @__PURE__ */ new Map();
var botWriting = 0;
var inboxSeq = 0;
function listen(bots, inbox, quietMs = 6e3) {
  if (!inbox || !bots.length) return;
  const b = bots[0];
  if (isBoard(b)) {
    listenBoard(b, inbox);
    return;
  }
  listenDocChat(b, inbox);
  const ours = new Set(bots.map((x) => x.doc.clientID));
  let baseline = b.text.toString();
  let timer = null;
  b.text.observe((e) => {
    const tr = e.transaction;
    let human = false;
    for (const [client, clock] of tr.afterState) {
      if (clock > (tr.beforeState.get(client) ?? 0) && !ours.has(client)) human = true;
    }
    const bulk = e.delta.reduce((n, d) => n + (typeof d.insert === "string" ? d.insert.length : 0), 0) > 300;
    if (!human || bulk) {
      if (!timer) baseline = b.text.toString();
      return;
    }
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      timer = null;
      const now = b.text.toString();
      let pre = 0;
      while (pre < now.length && pre < baseline.length && now[pre] === baseline[pre]) pre++;
      let suf = 0;
      while (suf < now.length - pre && suf < baseline.length - pre && now[now.length - 1 - suf] === baseline[baseline.length - 1 - suf]) suf++;
      let end = now.length - suf;
      const added = now.slice(pre, end).trim();
      baseline = now;
      if (!added) return;
      const nl = now.indexOf("\n\n", end);
      end = nl < 0 ? now.length : nl;
      const id2 = `m${++inboxSeq}`;
      threads.set(id2, { anchor: createRelativePositionFromTypeIndex(b.text, end, -1) });
      const author = humanName(b);
      deliverFor(b, inbox, { id: id2, at: (/* @__PURE__ */ new Date()).toISOString(), author, text: added, context: now.slice(Math.max(0, pre - 1500), pre) });
      log(`inbox ${id2} from ${author}: ${added.slice(0, 80).replace(/\n/g, " ")}`);
    }, quietMs);
  });
}
function humanName(b) {
  for (const [, st] of b.awareness.getStates()) {
    const u = st.user;
    if (u?.id && !u.id.startsWith("bot_")) return u.name ?? "someone";
  }
  return "someone";
}
async function reply(b, id2, body) {
  if (isBoard(b)) return boardReply(b, id2, body);
  if (docChatReply(b, id2, body)) return true;
  stopWorking(b);
  const t = threads.get(id2);
  if (!t) {
    log(`no inbox message ${id2}`);
    return false;
  }
  botWriting++;
  try {
    t.anchor = await typeAt(b, t.anchor, `

${body.replace(/\n*$/, "")}`);
  } finally {
    botWriting--;
  }
  log(`${b.name}: replied to ${id2}`);
  return true;
}
var authorOf = (b) => ({ id: b.id, name: b.name, agent: true });
function suggest(b, find2, replacement, opts = {}) {
  const at = b.text.toString().indexOf(find2, opts.from ?? 0);
  if (at < 0) {
    log(`${b.name}: "${find2.slice(0, 40)}" not found`);
    return null;
  }
  const s = suggestText(b.doc, { from: at, to: at + find2.length }, replacement, authorOf(b), { why: opts.why, runId: opts.runId });
  log(`${b.name}: suggested ${s.id}`);
  return s.id;
}
function isBoard(b) {
  return b.kind === "whiteboard";
}
function boardElements(b) {
  return elementsFromY(b.els);
}
var short = (s, n = 60) => s.length > n ? s.slice(0, n - 1) + "..." : s;
function boardSummary(b) {
  const els = boardElements(b);
  const lines = els.filter((e) => (e.text ?? "").trim() || e.name || e.type === DgElementType.Frame).map((e) => {
    const votes = e.votes ? Object.values(e.votes).reduce((a, n) => a + n, 0) : 0;
    return `  ${e.id}  ${e.type}${e.page ? ` p:${e.page}` : ""}  "${short((e.text ?? e.name ?? "").replace(/\n/g, " "))}"${votes ? `  votes:${votes}` : ""}`;
  });
  const disc = [...b.comments.values()].filter((c) => c.elementId === BOARD_THREAD_ID).sort((x, y) => x.createdAt.localeCompare(y.createdAt));
  const talk = disc.map((c) => `  ${c.id}  ${c.author.name}: ${short(c.body, 80)}`);
  return `--- board: ${els.length} elements ---
${lines.join("\n")}
--- discussion: ${disc.length} ---
${talk.join("\n")}
--- end ---`;
}
function findElement(b, ref) {
  const els = boardElements(b);
  const q = ref.trim().toLowerCase();
  return els.find((e) => e.id === ref) ?? els.find((e) => e.id.toLowerCase().startsWith(q)) ?? els.find((e) => (e.text ?? "").trim().toLowerCase().startsWith(q)) ?? els.find((e) => (e.text ?? "").toLowerCase().includes(q)) ?? null;
}
var stamp = () => ({ id: `c_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 7)}`, iso: (/* @__PURE__ */ new Date()).toISOString() });
function addSticky(b, text, opts = {}) {
  if (!mayWrite(b, "sticky")) return null;
  const els = boardElements(b);
  const mine = els.filter((e) => e.createdBy === b.id && e.type === DgElementType.Sticky).length;
  let x = 120, y = 120;
  const anchor = opts.near ? findElement(b, opts.near) : null;
  if (opts.x !== void 0 && opts.y !== void 0) {
    x = opts.x;
    y = opts.y;
  } else if (anchor) {
    const a = elementAabb(anchor);
    x = a.x + a.w + 24 + mine % 3 * 216;
    y = a.y + Math.floor(mine / 3) * 136;
  } else if (els.length) {
    const onPage = els.filter((e) => (opts.page ? e.page === opts.page : true) && e.createdBy !== b.id);
    const boxes = (onPage.length ? onPage : els).map(elementAabb);
    const maxX = Math.max(...boxes.map((r) => r.x + r.w));
    const minY = Math.min(...boxes.map((r) => r.y));
    x = maxX + 80 + mine % 2 * 230;
    y = minY + Math.floor(mine / 2) * 150;
  }
  const zs = els.map((e) => e.z);
  const el = makeElement(DgElementType.Sticky, Math.round(x), Math.round(y), 200, 120, zs, b.id);
  el.text = text;
  if (opts.page) el.page = opts.page;
  writeElToY(b.els, el);
  pointAt(b, el);
  log(`${b.name}: added sticky ${el.id} "${short(text)}"`);
  return el;
}
function setText(b, ref, text) {
  if (!mayWrite(b, "text")) return false;
  const el = findElement(b, ref);
  if (!el) {
    log(`${b.name}: no element matches "${ref}"`);
    return false;
  }
  const m = b.els.get(el.id);
  if (!(m instanceof YMap)) return false;
  const cur = m.get("text");
  m.doc?.transact(() => {
    if (cur instanceof YText) applyTextDiff(cur, text);
    else {
      const t = new YText();
      t.insert(0, text);
      m.set("text", t);
    }
    m.set("updatedAt", Date.now());
  });
  pointAt(b, el);
  log(`${b.name}: set ${el.id} to "${short(text)}"`);
  return true;
}
function moveElement(b, ref, x, y) {
  if (!mayWrite(b, "move")) return false;
  const el = findElement(b, ref);
  if (!el) {
    log(`${b.name}: no element matches "${ref}"`);
    return false;
  }
  const m = b.els.get(el.id);
  if (!(m instanceof YMap)) return false;
  b.doc.transact(() => {
    m.set("x", Math.round(x));
    m.set("y", Math.round(y));
    m.set("updatedAt", Date.now());
  });
  pointAt(b, { ...el, x, y });
  log(`${b.name}: moved ${el.id} to ${Math.round(x)},${Math.round(y)}`);
  return true;
}
function resizeElement(b, ref, w, h) {
  if (!mayWrite(b, "resize")) return false;
  const el = findElement(b, ref);
  if (!el) {
    log(`${b.name}: no element matches "${ref}"`);
    return false;
  }
  const m = b.els.get(el.id);
  if (!(m instanceof YMap)) return false;
  b.doc.transact(() => {
    m.set("w", Math.max(20, Math.round(w)));
    m.set("h", Math.max(20, Math.round(h)));
    m.set("updatedAt", Date.now());
  });
  pointAt(b, el);
  log(`${b.name}: resized ${el.id} to ${Math.round(w)}x${Math.round(h)}`);
  return true;
}
function vote(b, ref, remove = false) {
  if (!mayWrite(b, "vote")) return false;
  const el = findElement(b, ref);
  if (!el) {
    log(`${b.name}: no element matches "${ref}"`);
    return false;
  }
  const m = b.els.get(el.id);
  if (!(m instanceof YMap)) return false;
  const key2 = `vote.${b.id}`;
  const cur = m.get(key2) ?? 0;
  const next = remove ? Math.max(0, cur - 1) : cur + 1;
  if (next === 0) m.delete(key2);
  else m.set(key2, next);
  pointAt(b, el);
  log(`${b.name}: ${remove ? "took a vote back from" : "voted for"} ${el.id} "${short((el.text ?? "").replace(/\n/g, " "))}"`);
  return true;
}
function boardSay(b, body) {
  stopWorking(b);
  const s = stamp();
  const c = { id: s.id, elementId: BOARD_THREAD_ID, author: { id: b.id, name: b.name }, body: body.trim(), createdAt: s.iso, resolved: false, replies: [] };
  b.comments.set(c.id, c);
  log(`${b.name}: said in the discussion: ${short(body, 80)}`);
  return c.id;
}
function commentOn(b, ref, body) {
  const el = findElement(b, ref);
  if (!el) {
    log(`${b.name}: no element matches "${ref}"`);
    return null;
  }
  const s = stamp();
  const c = { id: s.id, elementId: el.id, author: { id: b.id, name: b.name }, body: body.trim(), createdAt: s.iso, resolved: false, replies: [] };
  b.comments.set(c.id, c);
  pointAt(b, el);
  log(`${b.name}: commented on ${el.id}: ${short(body, 80)}`);
  return c.id;
}
function boardReply(b, id2, body) {
  const c = b.comments.get(id2) ?? b.comments.get(replyParent.get(id2) ?? "");
  if (!c) {
    log(`${b.name}: no comment ${id2}`);
    return false;
  }
  if (c.elementId === BOARD_THREAD_ID) {
    boardSay(b, body);
    return true;
  }
  stopWorking(b);
  const s = stamp();
  b.comments.set(c.id, { ...c, replies: [...c.replies, { id: s.id, author: { id: b.id, name: b.name }, body: body.trim(), createdAt: s.iso }] });
  log(`${b.name}: replied on ${c.elementId}`);
  return true;
}
function pointAt(b, el) {
  const a = elementAabb(el);
  b.awareness.setLocalStateField("cursor", { x: a.x + a.w / 2, y: a.y + a.h / 2 });
  b.awareness.setLocalStateField("selection", [el.id]);
  const w = Math.max(640, a.w + 320), h = Math.max(400, a.h + 240);
  b.awareness.setLocalStateField("viewport", { x: a.x + a.w / 2 - w / 2, y: a.y + a.h / 2 - h / 2, zoom: 1, w, h });
}
var replyParent = /* @__PURE__ */ new Map();
function watchThreads(b, map3, inbox, where) {
  const seen = /* @__PURE__ */ new Set();
  const mark = () => {
    for (const c of map3.values()) {
      seen.add(c.id);
      for (const r of c.replies ?? []) seen.add(r.id);
    }
  };
  mark();
  let settled = false;
  setTimeout(() => {
    mark();
    settled = true;
  }, 4e3).unref();
  map3.observe(() => {
    if (!settled) return;
    for (const c of map3.values()) {
      const w = where(c);
      const fresh = [];
      if (!seen.has(c.id)) {
        seen.add(c.id);
        fresh.push(c);
      }
      for (const r of c.replies ?? []) if (!seen.has(r.id)) {
        seen.add(r.id);
        replyParent.set(r.id, c.id);
        fresh.push(r);
      }
      if (!w) continue;
      for (const m of fresh) {
        if (m.author.id === b.id) continue;
        if (m.author.id.startsWith("bot_") && addressFor(b.name, m.body).addressed !== "you" /* You */) continue;
        deliverFor(b, inbox, { id: m.id, at: m.createdAt, author: m.author.name, text: m.body, ...w });
        log(`inbox ${m.id} from ${m.author.name} (${w.kind}): ${short(m.body, 80)}`);
      }
    }
  });
}
function listenBoard(b, inbox) {
  watchThreads(b, b.comments, inbox, (c) => {
    if (c.elementId === BOARD_THREAD_ID) return { kind: "discussion" };
    const el = boardElements(b).find((e) => e.id === c.elementId);
    return { kind: "comment", elementId: c.elementId, elementText: el ? short((el.text ?? "").replace(/\n/g, " ")) : void 0 };
  });
}
var docComments = (b) => b.doc.getMap("comments");
function listenDocChat(b, inbox) {
  watchThreads(b, docComments(b), inbox, (c) => c.anchor?.kind === "doc" ? { kind: "discussion" } : { kind: "comment", elementText: c.anchor?.exact ? short(c.anchor.exact.replace(/\n/g, " ")) : void 0 });
}
function docSay(b, body) {
  stopWorking(b);
  const s = stamp();
  const c = { id: s.id, anchor: { kind: "doc" }, author: { id: b.id, name: b.name }, body: body.trim(), createdAt: s.iso, resolved: false, replies: [] };
  docComments(b).set(c.id, c);
  log(`${b.name}: said in the chat: ${short(body, 80)}`);
  return c.id;
}
function docChatReply(b, id2, body) {
  const map3 = docComments(b);
  const c = map3.get(id2) ?? map3.get(replyParent.get(id2) ?? "");
  if (!c) return false;
  if (c.anchor?.kind === "doc") {
    docSay(b, body);
    return true;
  }
  stopWorking(b);
  const s = stamp();
  map3.set(c.id, { ...c, replies: [...c.replies, { id: s.id, author: { id: b.id, name: b.name }, body: body.trim(), createdAt: s.iso }] });
  log(`${b.name}: replied on a comment`);
  return true;
}
var VIEWER = "https://deltagraph.submillisecond.com/";
function writeDelta(b, d, what) {
  b.doc.transact(() => {
    for (const el of d.upserts) writeElToY(b.els, { ...el, updatedAt: Date.now() });
    for (const id2 of d.removes) b.els.delete(id2);
  });
  const first = d.upserts.find((e) => typeof e.data?.dsl === "string");
  if (first) pointAt(b, first);
  for (const e of d.errors) log(`${b.name}: ${e}`);
  log(`${b.name}: ${what}: ${d.upserts.length} written, ${d.removes.length} removed`);
}
async function diagramSource(b) {
  const r = await boardService()({ action: "source" /* Source */, elements: boardElements(b) });
  return (r.omits.length ? `# also on the board, not editable as text: ${r.omits.join(", ")}
` : "") + r.source;
}
async function diagramLink(b, title) {
  const src2 = (await boardService()({ action: "source" /* Source */, elements: boardElements(b) })).source.replace(/ @\(-?\d+,-?\d+\)!?/g, "").replace(/^# .*\n/gm, "");
  return deltagraphHref(src2.trim(), VIEWER, title ? { title } : {});
}
async function setDiagram(b, sourceOrLink) {
  const src2 = /^https?:\/\/\S+#/.test(sourceOrLink.trim()) ? await dslFromHash(sourceOrLink.trim()) : sourceOrLink;
  if (!src2?.trim()) {
    log(`${b.name}: no diagram in that input`);
    return false;
  }
  writeDelta(b, await boardService()({ action: "set" /* Set */, elements: boardElements(b), source: src2 }), "set the diagram");
  return true;
}
async function editDiagram(b, ops) {
  const d = await boardService()({ action: "edit" /* Edit */, elements: boardElements(b), ops });
  if (!d.applied) {
    for (const e of d.errors) log(`${b.name}: ${e}`);
    log(`${b.name}: no edit applied`);
    return false;
  }
  writeDelta(b, d, `applied ${d.applied} of ${ops.length} edits`);
  return true;
}
async function relayout(b) {
  writeDelta(b, await boardService()({ action: "relayout" /* Relayout */, elements: boardElements(b) }), "relaid out the diagram");
}

// agent/mcp/rooms.ts
var CLOSE_REASON = {
  4001: "the owner removed this agent, or the share does not allow agents",
  4003: "the relay refused the agent's identity",
  4004: "the share was ended",
  4010: "the share is full (200 people)",
  4006: "this agent is already in the room in another session",
  4007: "a newer session of this agent took over",
  4008: "the owner did not let this agent in",
  4029: "the relay removed the agent for sending too fast"
};
function closeReason(code) {
  return CLOSE_REASON[code] ?? `the relay closed the room (${code})`;
}
var DOC_KEY = /^f_[a-z0-9]+_[a-z0-9]+$/i;
var Rooms = class {
  constructor(joiner2, envRelay) {
    this.joiner = joiner2;
    this.envRelay = envRelay;
  }
  rooms = /* @__PURE__ */ new Map();
  next = 1;
  latest = null;
  waiters = /* @__PURE__ */ new Set();
  list() {
    return [...this.rooms.values()];
  }
  /** A room by handle, or the one most recently joined when none is named. */
  get(handle) {
    const h = handle?.trim() || this.latest;
    const r = h ? this.rooms.get(h) : void 0;
    if (!r) {
      throw new Error(this.rooms.size ? `no room "${handle}". Open rooms: ${[...this.rooms.keys()].join(", ")}` : "not in any room yet: call deltalab_join with a share link or code first");
    }
    return r;
  }
  /** The live participant in a room, or a reason it cannot act. */
  live(handle) {
    const room = this.get(handle);
    this.refresh(room);
    if (room.state === "waiting" /* Waiting */) throw new Error(`${room.handle} is waiting for the owner to let the agent in`);
    if (room.state === "joining" /* Joining */) throw new Error(`${room.handle} is still joining`);
    if (room.state !== "live" /* Live */ || !room.bot) throw new Error(`${room.handle} is closed: ${room.reason ?? "left"}`);
    return { room, bot: room.bot };
  }
  /** Pick up an eviction the relay sent since the last look. */
  refresh(room) {
    if (room.state !== "live" /* Live */ || !room.bot) return;
    const code = room.bot.closes.find((c) => c >= 4e3);
    if (code !== void 0) {
      room.state = "closed" /* Closed */;
      room.reason = closeReason(code);
    }
  }
  /** Join by link (returns once synced) or by code (returns at once: the owner
   *  admits from the lobby, and the room goes live when they do). */
  async join(req) {
    const relayOverride = req.relay || this.envRelay;
    if (!req.link && !req.code) throw new Error("pass a share link or a share code");
    const given = (req.link ?? req.code ?? "").trim();
    if (DOC_KEY.test(given)) throw new Error(`"${given}" is a document key, not a share. Ask for the share code (like KQ47-XMP0, from Share) or the full share link including everything after #.`);
    if (req.link && !tokenFromInput(req.link) && normShareCode(req.link)) req = { ...req, code: req.link, link: void 0 };
    let payload = null;
    if (req.link) {
      const tok = tokenFromInput(req.link);
      const res = tok ? decodeShare(tok) : null;
      if (!res?.ok) throw new Error(`that link does not open a share: ${res ? res.reason : "not a deltalab share link"}`);
      if (res.payload.locked) throw new Error("this link is password-protected. Ask for an unlocked link, or join with the share code and the owner admits the agent.");
      payload = res.payload;
    }
    const code = req.code ? normShareCode(req.code) : null;
    if (!payload && !code) throw new Error(`"${req.code}" is not a share code (8 letters and digits, like KQ47-XMP0)`);
    const relay = this.joiner.relayFor(req.link, relayOverride);
    const handle = `r${this.next++}`;
    const room = {
      handle,
      title: payload?.name ?? `share ${code}`,
      kind: payload?.kind ?? "unknown",
      owner: payload?.owner ?? "",
      state: payload ? "joining" /* Joining */ : "waiting" /* Waiting */,
      bot: null,
      inbox: [],
      delivered: 0,
      joinedAt: Date.now()
    };
    this.rooms.set(handle, room);
    this.latest = handle;
    const enter = async (p) => {
      room.title = p.name || room.title;
      room.kind = p.kind;
      room.owner = p.owner;
      room.state = "joining" /* Joining */;
      const bot = await this.joiner.join(p, relay);
      room.bot = bot;
      this.joiner.listen(bot, (m) => {
        room.inbox.push(m);
        this.wake();
      });
      await this.joiner.settle(bot);
      room.state = "live" /* Live */;
      this.refresh(room);
      this.wake();
    };
    const fail2 = (e) => {
      room.state = "failed" /* Failed */;
      room.reason = e?.message ?? String(e);
      this.wake();
    };
    if (payload) {
      try {
        await enter(payload);
      } catch (e) {
        fail2(e);
      }
    } else {
      void this.joiner.knock(code, relay).then(enter, fail2);
    }
    return room;
  }
  leave(handle) {
    const room = this.get(handle);
    room.bot?.leave();
    room.state = "closed" /* Closed */;
    room.reason = "the agent left";
    if (this.latest === room.handle) {
      const open = this.list().filter((r) => r.state === "live" /* Live */ || r.state === "waiting" /* Waiting */);
      this.latest = open.length ? open[open.length - 1].handle : room.handle;
    }
    return room;
  }
  leaveAll() {
    for (const r of this.rooms.values()) if (r.bot && r.state !== "closed" /* Closed */) r.bot.leave();
  }
  /** Messages a person wrote since the last call, waiting up to `waitMs` for
   *  the first one. Across every room when no handle is given. */
  async inbox(handle, waitMs) {
    const rooms2 = handle ? [this.get(handle)] : this.list();
    const take = () => rooms2.flatMap((r) => {
      const fresh = r.inbox.slice(r.delivered).map((m) => ({ ...m, room: r.handle }));
      r.delivered = r.inbox.length;
      return fresh;
    });
    const pending = () => rooms2.some((r) => r.inbox.length > r.delivered);
    if (!pending() && waitMs > 0) {
      await new Promise((resolve) => {
        const check = () => {
          if (pending()) finish();
        };
        const finish = () => {
          clearTimeout(t);
          this.waiters.delete(check);
          resolve();
        };
        const t = setTimeout(finish, waitMs);
        this.waiters.add(check);
      });
    }
    return take();
  }
  wake() {
    for (const w of [...this.waiters]) w();
  }
};

// agent/mcp/tools.ts
var BoardAction2 = /* @__PURE__ */ ((BoardAction3) => {
  BoardAction3["Sticky"] = "sticky";
  BoardAction3["SetText"] = "set_text";
  BoardAction3["Vote"] = "vote";
  BoardAction3["Unvote"] = "unvote";
  BoardAction3["Comment"] = "comment";
  BoardAction3["Say"] = "say";
  BoardAction3["SetDiagram"] = "set_diagram";
  BoardAction3["EditDiagram"] = "edit_diagram";
  BoardAction3["Relayout"] = "relayout";
  BoardAction3["Move"] = "move";
  BoardAction3["Resize"] = "resize";
  return BoardAction3;
})(BoardAction2 || {});
var BOARD_ACTIONS = Object.values(BoardAction2);
function toBoardAction(v) {
  return typeof v === "string" && BOARD_ACTIONS.includes(v) ? v : null;
}
var ok = (text) => ({ content: [{ type: "text", text }] });
var fail = (text) => ({ content: [{ type: "text", text }], isError: true });
var ROOM_PROP = {
  type: "string",
  description: "Room handle from deltalab_join (r1, r2, ...). Omit for the room joined most recently."
};
var ROOM_RULES = [
  "You are a participant in a live, end-to-end encrypted deltalab document or board that people are editing at the same time.",
  "Everyone in the room sees you as a robot avatar with your name, your cursor, and who runs you.",
  "Read before you write (deltalab_read). Keep to the section or area you were asked to work on; other people and agents are writing elsewhere at the same moment.",
  "If your permission is suggest (a Review link, or the owner switched the whole document to Review), propose changes with deltalab_suggest. A direct write would be dropped by every other participant.",
  "When someone talks in the document, its chat or the board discussion, it arrives in deltalab_inbox. Answer with deltalab_reply; start a conversation or hand something over with deltalab_say. To keep a conversation going, call deltalab_inbox with wait_seconds.",
  "Leave with deltalab_leave when the work is done, so your avatar goes."
];
var WORKING_TOGETHER = [
  "Use the conversation to coordinate. Before a large change, say what you plan and ask for objections. When you disagree with a request or with another agent's work, say so, give the reason, and propose what you would do.",
  "Write in the room like a colleague in a team chat, in plain English: one point per message, two or three sentences, lead with the decision, change or question. No praise, thanks, greetings, sign-offs or introducing yourself. Say what changed and what you need next. Share work only through the room (a viewer link, the board, the document), never a file on disk, even when the other agent runs on the same machine. Before building on someone's work, ask them to confirm it is final.",
  "Settle the direction in the conversation first, then change the work in small steps and say what changed after each, so people can steer between steps.",
  "Other agents may be in the room. Agree who takes which part before you start, keep to your part, and review each other's work with suggestions or comments.",
  "The chat is one room for people and agents. Every message from a person reaches every agent; a message from another agent reaches you only when it tags you by name, so tag an agent's handle to hand it work. Each is marked with who it was for: to you (tagged by your name), to every agent (@agent-valkyrie-all or @agents), to everyone (@all), to someone else, or open (no tag). Answer what is to you, to every agent or to everyone. Leave a message tagged to someone else to them unless you hold something they need. Answer open talk when you are the only agent, or when it is plainly about your part.",
  "Tag people and agents by their handle, as typed in the chat (@agent-valkyrie-uruz, @Ada-Lovelace), when you ask something or hand work over; your own handle is your name."
];
var BY_KIND = [
  "Boards: talk in the board discussion (deltalab_board say) and comment on the element you mean; votes show which options have support. Evolve the diagram with edit_diagram, one change at a time, and read the board again before each change, because others edit it too.",
  "Documents (markdown, code and other text files): reply where you were asked (deltalab_reply), write under your own heading or at the lines you were given, and use deltalab_suggest on anyone else's text. In code, keep a change to the lines you were asked about and say what it does.",
  "Drawings, notebooks and record files (tasks, decisions, retros and the like) are not supported by these tools yet. If you are asked to work in one, say so rather than writing into it."
];
var SERVER_INSTRUCTIONS = [...ROOM_RULES, ...WORKING_TOGETHER, ...BY_KIND].join(" ");
function toolList() {
  return [
    {
      name: "deltalab_join" /* Join */,
      title: "Join a deltalab share",
      description: "Join a live deltalab document or board from a share link (https://deltalab.submillisecond.com/#/share/...) or a share code (like KQ47-XMP0). The agent joins under its own key with a robot avatar; the share key stays on this machine, the relay only ever sees ciphertext. A link joins at once. A code waits in the lobby until the owner admits the agent: check deltalab_status. Returns a room handle (r1, r2, ...), what the share is, and what you may do in it.",
      inputSchema: {
        type: "object",
        properties: {
          link: { type: "string", description: "The share link, exactly as given, including everything after #." },
          code: { type: "string", description: "A share code instead of a link: 8 letters and digits, the dash optional (KQ47-XMP0 or KQ47XMP0). A code passed as link works too. A document key (f_...) is not a share." },
          relay: { type: "string", description: "Relay websocket URL. Only needed for a localhost link (wss://beta.collab.submillisecond.com for local development)." }
        }
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true }
    },
    {
      name: "deltalab_status" /* Status */,
      title: "Rooms and who is in them",
      description: "Every room this agent holds: state, permission (edit, suggest or view), whether the owner has the document in Review, who else is present, unread inbox messages.",
      inputSchema: { type: "object", properties: {} },
      annotations: { readOnlyHint: true, openWorldHint: true }
    },
    {
      name: "deltalab_read" /* Read */,
      title: "Read the document or board",
      description: "Read the shared content as it is right now. A document comes back with line numbers and its heading outline; a board comes back as every element with text (ids you can pass to deltalab_board), the discussion, the diagram as deltagraph DSL and a viewer link. Read again before writing if time has passed: other people are editing.",
      inputSchema: {
        type: "object",
        properties: {
          room: ROOM_PROP,
          from_line: { type: "integer", minimum: 1, description: "Document: first line to return." },
          to_line: { type: "integer", minimum: 1, description: "Document: last line to return." },
          numbered: { type: "boolean", description: "Document: prefix each line with its number (default true)." }
        }
      },
      annotations: { readOnlyHint: true, openWorldHint: true }
    },
    {
      name: "deltalab_write" /* Write */,
      title: "Write into the document",
      description: "Write markdown into a shared document directly. Put it under a heading (the end of that section), after a line, or at the end. Prefer under_heading: it is the spot that stays right while others edit. Refused when your permission is suggest or view; use deltalab_suggest then. Boards use deltalab_board.",
      inputSchema: {
        type: "object",
        properties: {
          room: ROOM_PROP,
          text: { type: "string", description: "Markdown to insert." },
          under_heading: { type: "string", description: "Heading text (without #s) whose section gets the text at its end." },
          after_line: { type: "integer", minimum: 1, description: "Insert on a new line after this 1-based line." }
        },
        required: ["text"]
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true }
    },
    {
      name: "deltalab_suggest" /* Suggest */,
      title: "Suggest a change",
      description: "Propose replacing text in a document; the owner sees it inline with Accept and Reject. Use it whenever your permission is suggest, and for any change to someone else's words even when you may edit. `find` must match the document exactly (copy it from deltalab_read); the first match is used.",
      inputSchema: {
        type: "object",
        properties: {
          room: ROOM_PROP,
          find: { type: "string", description: "Exact text to replace." },
          replace: { type: "string", description: "What it becomes. Empty to propose deleting it." },
          why: { type: "string", description: "One line the owner reads beside the suggestion." }
        },
        required: ["find", "replace"]
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true }
    },
    {
      name: "deltalab_board" /* Board */,
      title: "Act on a board",
      description: "Change a board. Actions: sticky (text; it lands to the right of the board's content unless near=<ref> places it beside an element or x and y place it exactly), set_text (ref, text), vote / unvote (ref), move (ref, x, y: the element's top-left corner), resize (ref, w, h), comment (ref, text: a thread on an element), say (text: the board discussion), set_diagram (dsl: deltagraph DSL or a deltagraph link; placed nodes keep their place, stickies and frames are untouched), edit_diagram (ops: add_node, remove_node, rename, add_edge, remove_edge, set_direction, move_to_group, add_group), relayout (re-solves the whole diagram and drops positions people set; avoid it on an arranged board). Diagram node positions are written as @(x,y) in the DSL and set_diagram keeps them; the engine stacks each subgraph in its own band, so placing sections side by side means writing positions. move and resize suit stickies and anything the diagram does not own; set_diagram re-sizes diagram nodes from their labels. <ref> is an element id from deltalab_read, an id prefix, or the start of its text.",
      inputSchema: {
        type: "object",
        properties: {
          room: ROOM_PROP,
          action: { type: "string", enum: BOARD_ACTIONS },
          ref: { type: "string", description: "Element to act on." },
          text: { type: "string" },
          near: { type: "string", description: "sticky: place it beside this element." },
          x: { type: "number", description: "sticky, move: left edge in board units." },
          y: { type: "number", description: "sticky, move: top edge in board units." },
          w: { type: "number", description: "resize: width in board units." },
          h: { type: "number", description: "resize: height in board units." },
          dsl: { type: "string", description: "set_diagram: deltagraph DSL, or a deltagraph viewer link." },
          ops: { type: "array", items: { type: "object" }, description: "edit_diagram: deltagraph edit operations." }
        },
        required: ["action"]
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true }
    },
    {
      name: "deltalab_inbox" /* Inbox */,
      title: "What people said to the agent",
      description: "Messages from people since the last call: a paragraph someone typed in the document once they paused, or a discussion message or comment on a board. Each has an id for deltalab_reply. With wait_seconds it waits for the first new message, which is how to hold a conversation.",
      inputSchema: {
        type: "object",
        properties: {
          room: { ...ROOM_PROP, description: "Room handle. Omit for every room." },
          wait_seconds: { type: "integer", minimum: 0, maximum: 55, description: "Wait this long for a message when there is none (default 0)." }
        }
      },
      annotations: { readOnlyHint: true, openWorldHint: true }
    },
    {
      name: "deltalab_reply" /* Reply */,
      title: "Reply to a message",
      description: "Answer an inbox message where it was written: below their paragraph in a document, in the same thread on a board.",
      inputSchema: {
        type: "object",
        properties: { room: ROOM_PROP, id: { type: "string" }, text: { type: "string" } },
        required: ["id", "text"]
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true }
    },
    {
      name: "deltalab_say" /* Say */,
      title: "Say something in the chat",
      description: "Post a message in the room's chat: the document's discussion, or the board's. Tag someone with @ and their handle (@agent-valkyrie-uruz, @agent-valkyrie-all, @all) to ask them or hand work over. For an answer to an inbox message use deltalab_reply.",
      inputSchema: {
        type: "object",
        properties: { room: ROOM_PROP, text: { type: "string" } },
        required: ["text"]
      },
      annotations: { readOnlyHint: false, destructiveHint: false, openWorldHint: true }
    },
    {
      name: "deltalab_leave" /* Leave */,
      title: "Leave a room",
      description: "Leave the room; the agent's avatar and cursor go at once.",
      inputSchema: { type: "object", properties: { room: ROOM_PROP } },
      annotations: { readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: true }
    }
  ];
}
var ADDRESS_WORDS = {
  ["you" /* You */]: "to you",
  ["agents" /* Agents */]: "to every agent",
  ["everyone" /* Everyone */]: "to everyone",
  ["others" /* Others */]: "to someone else",
  ["open" /* Open */]: "open, no tag"
};
function formatInboxLine(m) {
  const where = m.kind === "comment" ? ` on "${m.elementText ?? m.elementId ?? "a passage"}"` : m.kind === "discussion" ? " in the chat" : "";
  const to = m.addressed === "others" /* Others */ && m.to?.length ? `to ${m.to.map((h) => "@" + h).join(", ")}` : m.addressed ? ADDRESS_WORDS[m.addressed] : "";
  return `[${m.room} ${m.id}] ${m.author}${where}${to ? `, ${to}` : ""}:
${m.text}`;
}
var PERMISSION_WORDS = {
  edit: "edit: you may write directly",
  suggest: "suggest: propose changes with deltalab_suggest; direct writes are refused",
  view: "view only: read and talk, no changes"
};
function peopleIn(bot) {
  const seen = /* @__PURE__ */ new Map();
  for (const [, st] of bot.awareness.getStates()) {
    const u = st.user;
    if (u?.id && u.id !== bot.id) seen.set(u.id, `${u.name ?? u.id}${u.agent ? " (agent)" : ""}`);
  }
  return [...seen.values()];
}
function describeRoom(room) {
  const head = `${room.handle}: "${room.title}" (${room.kind === "whiteboard" ? "board" : room.kind})${room.owner ? ` by ${room.owner}` : ""}`;
  if (room.state !== "live" /* Live */ || !room.bot) {
    const why = room.state === "waiting" /* Waiting */ ? "waiting in the lobby for the owner to admit the agent" : room.reason ?? room.state;
    return `${head}
  state: ${room.state}${why && why !== room.state ? ` - ${why}` : ""}`;
  }
  const b = room.bot;
  const people = peopleIn(b);
  const unread = room.inbox.length - room.delivered;
  return [
    head,
    `  you are: ${b.name}`,
    `  permission: ${PERMISSION_WORDS[b.permission()]}`,
    `  here: ${people.length ? people.join(", ") : "nobody else right now"}`,
    `  inbox: ${unread ? `${unread} unread` : "nothing new"}`
  ].join("\n");
}
function documentView(bot, from2, to, numbered = true) {
  const lines = bot.text.toString().split("\n");
  const a = Math.max(1, from2 ?? 1);
  const z = Math.min(lines.length, to ?? lines.length);
  const width = String(z).length;
  const body = lines.slice(a - 1, z).map((l, i) => numbered ? `${String(a + i).padStart(width)}| ${l}` : l).join("\n");
  const heads = outline(bot).map((h) => `${"  ".repeat(h.level - 1)}- ${h.text} (line ${h.line})`);
  return [
    `--- outline ---`,
    heads.length ? heads.join("\n") : "(no headings)",
    `--- lines ${a}-${z} of ${lines.length} ---`,
    body,
    `--- end ---`
  ].join("\n");
}
var str = (v) => typeof v === "string" && v.length ? v : void 0;
var num = (v) => typeof v === "number" && Number.isFinite(v) ? v : void 0;
var int = (v) => typeof v === "number" && Number.isFinite(v) ? Math.trunc(v) : void 0;
function needsDoc(room, bot) {
  if (isBoard(bot)) throw new Error(`${room.handle} is a board: use deltalab_board`);
}
function refuseUnlessEdit(bot) {
  const p = bot.permission();
  if (p === "suggest") throw new Error("the document is in Review for you: propose the change with deltalab_suggest");
  if (p === "view") throw new Error("this agent has view-only access: it can read and talk, not change anything");
}
async function callTool(rooms2, name, args2) {
  try {
    switch (name) {
      case "deltalab_join" /* Join */: {
        const room = await rooms2.join({ link: str(args2.link), code: str(args2.code), relay: str(args2.relay) });
        if (room.state === "failed" /* Failed */) return fail(`could not join: ${room.reason}`);
        const next = room.state === "waiting" /* Waiting */ ? "The owner has to admit the agent. Call deltalab_status to see when the room goes live." : room.bot && isBoard(room.bot) ? "Next: deltalab_read to see the board." : "Next: deltalab_read to see the document.";
        return ok(`${describeRoom(room)}

${next}`);
      }
      case "deltalab_status" /* Status */: {
        const all2 = rooms2.list();
        for (const r of all2) rooms2.refresh(r);
        return ok(all2.length ? all2.map(describeRoom).join("\n\n") : "Not in any room. Call deltalab_join with a share link or code.");
      }
      case "deltalab_read" /* Read */: {
        const { room, bot } = rooms2.live(str(args2.room));
        if (isBoard(bot)) {
          let src2 = "", link = "", unreachable = "";
          try {
            src2 = await diagramSource(bot);
            link = src2.trim() ? await diagramLink(bot, room.title) : "";
          } catch (e) {
            unreachable = `(the diagram could not be read: ${e?.message ?? e})`;
          }
          return ok([boardSummary(bot), "--- diagram (deltagraph DSL) ---", unreachable || src2.trim() || "(no diagram)", link ? `viewer: ${link}` : ""].filter(Boolean).join("\n"));
        }
        return ok(`${describeRoom(room)}

${documentView(bot, int(args2.from_line), int(args2.to_line), args2.numbered !== false)}`);
      }
      case "deltalab_write" /* Write */: {
        const { room, bot } = rooms2.live(str(args2.room));
        needsDoc(room, bot);
        refuseUnlessEdit(bot);
        const text = str(args2.text);
        if (!text) return fail("text is empty");
        const heading = str(args2.under_heading);
        const after = int(args2.after_line);
        if (heading) {
          const done = await writeUnder(bot, heading, text);
          if (done === null) return fail(`no heading "${heading}". Headings: ${outline(bot).map((h) => h.text).join(" | ") || "none"}`);
          return ok(`wrote ${text.length} chars at the end of "${heading}"`);
        }
        if (after) {
          await typeAt(bot, lineEnd(bot.text, after), `
${text.replace(/\n*$/, "")}`);
          return ok(`wrote ${text.length} chars after line ${after}`);
        }
        await appendParagraph(bot, text);
        return ok(`wrote ${text.length} chars at the end of the document`);
      }
      case "deltalab_suggest" /* Suggest */: {
        const { room, bot } = rooms2.live(str(args2.room));
        needsDoc(room, bot);
        if (bot.permission() === "view") return fail("this agent has view-only access and cannot suggest");
        const find2 = typeof args2.find === "string" ? args2.find : "";
        if (!find2) return fail("find is empty");
        const id2 = suggest(bot, find2, typeof args2.replace === "string" ? args2.replace : "", { why: str(args2.why) });
        if (!id2) return fail(`"${find2.slice(0, 60)}" is not in the document. Copy the text exactly from deltalab_read (without line numbers).`);
        return ok(`suggested ${id2}; the owner sees it with Accept and Reject`);
      }
      case "deltalab_board" /* Board */: {
        const { room, bot } = rooms2.live(str(args2.room));
        if (!isBoard(bot)) return fail(`${room.handle} is a document: use deltalab_write or deltalab_suggest`);
        const action = toBoardAction(args2.action);
        if (!action) return fail(`action must be one of: ${BOARD_ACTIONS.join(", ")}`);
        const ref = str(args2.ref);
        const text = str(args2.text);
        refuseUnlessEdit(bot);
        switch (action) {
          case "sticky" /* Sticky */: {
            if (!text) return fail("sticky needs text");
            const el = addSticky(bot, text, { near: str(args2.near), x: num(args2.x), y: num(args2.y) });
            return el ? ok(`added sticky ${el.id}`) : fail("could not add the sticky");
          }
          case "set_text" /* SetText */:
            if (!ref || text === void 0) return fail("set_text needs ref and text");
            return setText(bot, ref, text) ? ok(`set the text of ${ref}`) : fail(`no element matches "${ref}"`);
          case "vote" /* Vote */:
          case "unvote" /* Unvote */:
            if (!ref) return fail(`${action} needs ref`);
            return vote(bot, ref, action === "unvote" /* Unvote */) ? ok(`${action === "vote" /* Vote */ ? "voted for" : "took a vote back from"} ${ref}`) : fail(`no element matches "${ref}"`);
          case "comment" /* Comment */: {
            if (!ref || !text) return fail("comment needs ref and text");
            const id2 = commentOn(bot, ref, text);
            return id2 ? ok(`commented on ${ref} (${id2})`) : fail(`no element matches "${ref}"`);
          }
          case "say" /* Say */:
            if (!text) return fail("say needs text");
            return ok(`said it in the discussion (${boardSay(bot, text)})`);
          case "set_diagram" /* SetDiagram */: {
            const dsl = str(args2.dsl);
            if (!dsl) return fail("set_diagram needs dsl");
            return await setDiagram(bot, dsl) ? ok("set the diagram") : fail("no diagram in that input");
          }
          case "edit_diagram" /* EditDiagram */: {
            if (!Array.isArray(args2.ops) || !args2.ops.length) return fail("edit_diagram needs ops");
            return await editDiagram(bot, args2.ops) ? ok(`applied the edits`) : fail("no edit applied: check the node ids against deltalab_read");
          }
          case "relayout" /* Relayout */:
            await relayout(bot);
            return ok("relaid out the diagram");
          case "move" /* Move */: {
            const x = num(args2.x), y = num(args2.y);
            if (!ref || x === void 0 || y === void 0) return fail("move needs ref, x and y");
            return moveElement(bot, ref, x, y) ? ok(`moved ${ref} to ${Math.round(x)},${Math.round(y)}`) : fail(`no element matches "${ref}"`);
          }
          case "resize" /* Resize */: {
            const w = num(args2.w), h = num(args2.h);
            if (!ref || w === void 0 || h === void 0) return fail("resize needs ref, w and h");
            return resizeElement(bot, ref, w, h) ? ok(`resized ${ref} to ${Math.round(w)}x${Math.round(h)}`) : fail(`no element matches "${ref}"`);
          }
        }
        return fail("unknown action");
      }
      case "deltalab_inbox" /* Inbox */: {
        const wait = Math.min(55, Math.max(0, int(args2.wait_seconds) ?? 0));
        const msgs = await rooms2.inbox(str(args2.room), wait * 1e3);
        if (!msgs.length) return ok(wait ? `nothing new in ${wait}s` : "nothing new");
        return ok(msgs.map((m) => formatInboxLine(m)).join("\n\n"));
      }
      case "deltalab_reply" /* Reply */: {
        const { bot } = rooms2.live(str(args2.room));
        const id2 = str(args2.id);
        const text = str(args2.text);
        if (!id2 || !text) return fail("reply needs id and text");
        refuseUnlessEdit(bot);
        return await reply(bot, id2, text) ? ok(`replied to ${id2}`) : fail(`no inbox message ${id2}`);
      }
      case "deltalab_say" /* Say */: {
        const { bot } = rooms2.live(str(args2.room));
        const text = str(args2.text);
        if (!text) return fail("say needs text");
        refuseUnlessEdit(bot);
        const id2 = isBoard(bot) ? boardSay(bot, text) : docSay(bot, text);
        return ok(`said in the chat (${id2})`);
      }
      case "deltalab_leave" /* Leave */: {
        const room = rooms2.leave(str(args2.room));
        return ok(`left ${room.handle} ("${room.title}")`);
      }
      default:
        return fail(`unknown tool: ${name}`);
    }
  } catch (e) {
    return fail(e?.message ?? String(e));
  }
}

// agent/mcp/server.ts
var MCP_PROTOCOL_VERSION = "2025-06-18";
var MCP_SERVER_INFO = { name: "deltalab", title: "deltalab", version: "0.3.0" };
async function handleMcpMessage(rooms2, msg) {
  const req = msg;
  if (!req || req.jsonrpc !== "2.0" || typeof req.method !== "string") {
    return { jsonrpc: "2.0", id: req?.id ?? null, error: { code: -32600, message: "invalid request" } };
  }
  const id2 = req.id ?? null;
  const isNotification = req.id === void 0;
  switch (req.method) {
    case "initialize":
      return {
        jsonrpc: "2.0",
        id: id2,
        result: { protocolVersion: MCP_PROTOCOL_VERSION, capabilities: { tools: {} }, serverInfo: MCP_SERVER_INFO, instructions: SERVER_INSTRUCTIONS }
      };
    case "ping":
      return { jsonrpc: "2.0", id: id2, result: {} };
    case "tools/list":
      return { jsonrpc: "2.0", id: id2, result: { tools: toolList() } };
    case "tools/call": {
      const p = req.params ?? {};
      const name = typeof p.name === "string" ? p.name : "";
      const args2 = p.arguments && typeof p.arguments === "object" ? p.arguments : {};
      return { jsonrpc: "2.0", id: id2, result: await callTool(rooms2, name, args2) };
    }
    default:
      if (isNotification) return null;
      return { jsonrpc: "2.0", id: id2, error: { code: -32601, message: `method not found: ${req.method}` } };
  }
}
function serveMcp(rooms2, input, output) {
  return new Promise((resolve) => {
    let buf = "";
    input.setEncoding?.("utf8");
    input.on("data", (chunk) => {
      buf += chunk;
      let nl;
      while ((nl = buf.indexOf("\n")) >= 0) {
        const line = buf.slice(0, nl).trim();
        buf = buf.slice(nl + 1);
        if (!line) continue;
        let msg;
        try {
          msg = JSON.parse(line);
        } catch {
          output.write(JSON.stringify({ jsonrpc: "2.0", id: null, error: { code: -32700, message: "parse error" } }) + "\n");
          continue;
        }
        void handleMcpMessage(rooms2, msg).catch((e) => ({ jsonrpc: "2.0", id: msg.id ?? null, error: { code: -32603, message: e?.message ?? "internal error" } })).then((res) => {
          if (res) output.write(JSON.stringify(res) + "\n");
        });
      }
    });
    input.on("end", () => resolve());
  });
}

// scripts/deltalab-mcp.ts
if (typeof globalThis.WebSocket !== "function" || typeof globalThis.crypto?.subtle !== "object") {
  process.stderr.write("deltalab: needs Node 22 or newer (built-in WebSocket and WebCrypto). Found " + process.version + "\n");
  process.exit(1);
}
setAgentLog((line) => process.stderr.write(`deltalab: ${line}
`));
var serial = Math.floor(Math.random() * 999) + 1;
var NAME = mentionHandle(process.env.DELTALAB_AGENT_NAME?.trim() || "") || agentHandle(Math.floor(Math.random() * VALKYRIE_RUNES.length));
var RUN_BY = process.env.DELTALAB_RUN_BY?.trim() || (() => {
  try {
    return userInfo().username;
  } catch {
    return "";
  }
})();
var me = null;
var self = () => me ??= identity(NAME, serial, RUN_BY || void 0);
var joiner = {
  relayFor: (link, override) => {
    if (override) return override;
    return link ? relayFor(link) : "wss://collab.submillisecond.com";
  },
  knock: async (code, relay) => knockFor(code, await self(), relay),
  join: async (payload, relay) => joinWith(payload, await self(), relay),
  listen: (bot, sink) => listen([bot], sink),
  settle: async (bot) => {
    for (let i = 0; i < 80 && !bot.ws.synced; i++) await sleep(100);
    await sleep(800);
  }
};
var rooms = new Rooms(joiner, process.env.DELTALAB_RELAY?.trim() || void 0);
var bye = () => {
  rooms.leaveAll();
  setTimeout(() => process.exit(0), 400);
};
process.on("SIGINT", bye);
process.on("SIGTERM", bye);
await serveMcp(rooms, process.stdin, process.stdout);
bye();
