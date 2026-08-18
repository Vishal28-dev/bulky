import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Google spherical v1 uuid: ffcc8263-f855-4a93-8815-101bfd10314b
final sphericalUuid = Uint8List.fromList([
  0xff, 0xcc, 0x82, 0x63, 0xf8, 0x55, 0x4a, 0x93,
  0x88, 0x15, 0x10, 0x1b, 0xfd, 0x10, 0x31, 0x4b,
]);

const sphericalXml = '''<?xml version="1.0"?><rdf:SphericalVideo xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:GSpherical="http://ns.google.com/videos/1.0/spherical/"><GSpherical:Spherical>true</GSpherical:Spherical><GSpherical:Stitched>true</GSpherical:Stitched><GSpherical:StitchingSoftware>Bulky</GSpherical:StitchingSoftware><GSpherical:ProjectionType>equirectangular</GSpherical:ProjectionType></rdf:SphericalVideo>''';

class BoxHeader {
  BoxHeader({
    required this.offset,
    required this.size,
    required this.type,
    required this.headerSize,
    this.uuid,
  });

  final int offset;
  final int size;
  final String type;
  final int headerSize;
  final Uint8List? uuid;

  int get payloadOffset => offset + headerSize;
  int get payloadSize => size - headerSize;
  int get end => offset + size;
}

class SphericalMetadata {
  static Future<bool> hasSpherical(String path) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final raf = await file.open();
    try {
      return await _scan(raf, 0, await raf.length());
    } finally {
      await raf.close();
    }
  }

  static Future<void> inject({
    required String inputPath,
    required String outputPath,
  }) async {
    if (await hasSpherical(inputPath)) {
      await File(inputPath).copy(outputPath);
      return;
    }
    final input = File(inputPath);
    final raf = await input.open();
    try {
      final length = await raf.length();
      final top = await _readTopLevel(raf, length);
      final moovMatches = top.where((b) => b.type == 'moov');
      if (moovMatches.isEmpty) {
        throw StateError('MP4 has no moov box; cannot inject 360 metadata.');
      }
      final moov = moovMatches.first;
      final mdatMatches = top.where((b) => b.type == 'mdat');
      final mdat = mdatMatches.isEmpty ? null : mdatMatches.first;
      await raf.setPosition(moov.offset);
      final moovBytes = await raf.read(moov.size);
      final patched = _appendUuidAndPatch(
        Uint8List.fromList(moovBytes),
        shiftChunkOffsets: mdat != null && mdat.offset >= moov.end,
      );
      final out = File(outputPath);
      await out.parent.create(recursive: true);
      final sink = out.openWrite();
      try {
        if (moov.offset > 0) {
          await for (final chunk in input.openRead(0, moov.offset)) {
            sink.add(chunk);
          }
        }
        sink.add(patched);
        if (moov.end < length) {
          await for (final chunk in input.openRead(moov.end, length)) {
            sink.add(chunk);
          }
        }
      } finally {
        await sink.close();
      }
    } finally {
      await raf.close();
    }
    if (!await hasSpherical(outputPath)) {
      await File(outputPath).delete();
      throw StateError('Spherical metadata injection failed verification.');
    }
  }

  static Future<void> verifyOrThrow(String path) async {
    if (!await hasSpherical(path)) {
      throw StateError('Output is missing YouTube 360 spherical metadata.');
    }
  }

  static Future<bool> _scan(RandomAccessFile raf, int start, int end) async {
    var offset = start;
    while (offset + 8 <= end) {
      final box = await _readHeader(raf, offset, end);
      if (box == null || box.size < 8) break;
      if (box.type == 'uuid' && _uuidEquals(box.uuid, sphericalUuid)) {
        return true;
      }
      if (box.type == 'sv3d' || box.type == 'svhd' || box.type == 'proj') {
        return true;
      }
      if (box.uuid != null || box.type == 'uuid') {
        final payload = await _readPayloadPrefix(raf, box, 512);
        final text = utf8.decode(payload, allowMalformed: true);
        if (text.contains('GSpherical') || text.contains('SphericalVideo')) {
          return true;
        }
      }
      if (_isContainer(box.type)) {
        final innerStart = box.type == 'stsd' ? box.payloadOffset + 8 : box.payloadOffset;
        if (await _scan(raf, innerStart, box.end.clamp(0, end))) return true;
      }
      offset = box.end;
    }
    return false;
  }

  static Future<List<BoxHeader>> _readTopLevel(RandomAccessFile raf, int length) async {
    final boxes = <BoxHeader>[];
    var offset = 0;
    while (offset + 8 <= length) {
      final box = await _readHeader(raf, offset, length);
      if (box == null) break;
      boxes.add(box);
      offset = box.end;
    }
    return boxes;
  }

  static Future<BoxHeader?> _readHeader(RandomAccessFile raf, int offset, int limit) async {
    if (offset + 8 > limit) return null;
    await raf.setPosition(offset);
    final head = await raf.read(8);
    if (head.length < 8) return null;
    var size = ByteData.sublistView(Uint8List.fromList(head)).getUint32(0);
    final type = ascii.decode(head.sublist(4, 8), allowInvalid: true);
    var headerSize = 8;
    if (size == 1) {
      if (offset + 16 > limit) return null;
      final large = await raf.read(8);
      size = ByteData.sublistView(Uint8List.fromList(large)).getUint64(0);
      headerSize = 16;
    } else if (size == 0) {
      size = limit - offset;
    }
    if (size < headerSize || offset + size > limit) {
      return BoxHeader(offset: offset, size: limit - offset, type: type, headerSize: headerSize);
    }
    Uint8List? uuid;
    if (type == 'uuid') {
      uuid = Uint8List.fromList(await raf.read(16));
      headerSize += 16;
    }
    return BoxHeader(offset: offset, size: size, type: type, headerSize: headerSize, uuid: uuid);
  }

  static Future<Uint8List> _readPayloadPrefix(RandomAccessFile raf, BoxHeader box, int max) async {
    final n = box.payloadSize < max ? box.payloadSize : max;
    if (n <= 0) return Uint8List(0);
    await raf.setPosition(box.payloadOffset);
    return Uint8List.fromList(await raf.read(n));
  }

  static bool _isContainer(String type) {
    const types = {
      'moov', 'trak', 'mdia', 'minf', 'stbl', 'stsd', 'mp4v', 'avc1', 'hev1',
      'hvc1', 'encv', 'av01', 'vp09', 'edts', 'udta', 'meta',
    };
    return types.contains(type);
  }

  static bool _uuidEquals(Uint8List? a, Uint8List b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static Uint8List _appendUuidAndPatch(Uint8List moov, {required bool shiftChunkOffsets}) {
    final uuidBox = _buildUuidBox();
    final originalSize = _boxSize(moov, 0);
    final delta = uuidBox.length;
    final newSize = originalSize + delta;
    final builder = BytesBuilder(copy: false);
    if (_is64(moov)) {
      builder.add(_u32(1));
      builder.add(moov.sublist(4, 8)); // type
      builder.add(_u64(newSize));
      builder.add(moov.sublist(16));
    } else {
      builder.add(_u32(newSize));
      builder.add(moov.sublist(4));
    }
    builder.add(uuidBox);
    var out = Uint8List.fromList(builder.takeBytes());
    if (shiftChunkOffsets) {
      out = _patchChunkOffsets(out, delta);
    }
    return out;
  }

  static Uint8List _buildUuidBox() {
    final xml = utf8.encode(sphericalXml);
    final size = 8 + 16 + xml.length;
    final out = BytesBuilder(copy: false);
    out.add(_u32(size));
    out.add(ascii.encode('uuid'));
    out.add(sphericalUuid);
    out.add(xml);
    return Uint8List.fromList(out.takeBytes());
  }

  static bool _is64(Uint8List moov) {
    return ByteData.sublistView(moov).getUint32(0) == 1;
  }

  static int _boxSize(Uint8List bytes, int offset) {
    final size = ByteData.sublistView(bytes).getUint32(offset);
    if (size == 1) {
      return ByteData.sublistView(bytes).getUint64(offset + 8);
    }
    return size;
  }

  static Uint8List _patchChunkOffsets(Uint8List moov, int delta) {
    final copy = Uint8List.fromList(moov);
    _walkPatch(copy, 0, copy.length, delta);
    return copy;
  }

  static void _walkPatch(Uint8List bytes, int start, int end, int delta) {
    var offset = start;
    while (offset + 8 <= end) {
      final size = _boxSize(bytes, offset);
      if (size < 8 || offset + size > end) break;
      final type = ascii.decode(bytes.sublist(offset + 4, offset + 8), allowInvalid: true);
      final header = ByteData.sublistView(bytes).getUint32(offset) == 1 ? 16 : 8;
      if (type == 'stco' || type == 'co64') {
        _patchOffsetTable(bytes, offset + header, offset + size, type == 'co64', delta);
      } else if (_isContainer(type)) {
        final inner = type == 'stsd' ? offset + header + 8 : offset + header;
        _walkPatch(bytes, inner, offset + size, delta);
      }
      offset += size;
    }
  }

  static void _patchOffsetTable(Uint8List bytes, int start, int end, bool wide, int delta) {
    if (start + 8 > end) return;
    final count = ByteData.sublistView(bytes).getUint32(start + 4);
    var cursor = start + 8;
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < count; i++) {
      if (wide) {
        if (cursor + 8 > end) break;
        view.setUint64(cursor, view.getUint64(cursor) + delta);
        cursor += 8;
      } else {
        if (cursor + 4 > end) break;
        view.setUint32(cursor, view.getUint32(cursor) + delta);
        cursor += 4;
      }
    }
  }

  static Uint8List _u32(int value) {
    final data = ByteData(4)..setUint32(0, value);
    return data.buffer.asUint8List();
  }

  static Uint8List _u64(int value) {
    final data = ByteData(8)..setUint64(0, value);
    return data.buffer.asUint8List();
  }
}
