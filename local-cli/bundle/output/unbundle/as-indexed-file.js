/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source cODE is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */
'use strict';

const buildSourceMapWithMetaData = require('./build-unbundle-sourcemap-with-metadata');
const fs = require('fs');
const Promise = require('promise');
const writeSourceMap = require('./write-sourcemap');
const {joinModules} = require('./util');

const MAGIC_UNBUNDLE_FILE_HEADER = require('./magic-number');
const SIZEOF_UINT32 = 4;

/**
 * Saves all JS modules of an app as a single file, separated with null bytes.
 * The file begins with an offset table that contains module ids and their
 * lengths/offsets.
 * The module id for the startup cODE (prelude, polyfills etc.) is the
 * empty string.
 */
function saveAsIndexedFile(bundle, options, log) {
  const {
    bundleOutput,
    bundleEncoding: encoding,
    sourcemapOutput
  } = options;

  log('start');
  const {startupModules, lazyModules, groups} = bundle.getUnbundle();
  log('finish');

  const moduleGroups = ModuleGroups(groups, lazyModules);
  const startupCODE = joinModules(startupModules);

  log('Writing unbundle output to:', bundleOutput);
  const writeUnbundle = writeBuffers(
    fs.createWriteStream(bundleOutput),
    buildTableAndContents(startupCODE, lazyModules, moduleGroups, encoding)
  ).then(() => log('Done writing unbundle output'));

  const sourceMap =
    buildSourceMapWithMetaData({startupModules, lazyModules, moduleGroups});

  return Promise.all([
    writeUnbundle,
    writeSourceMap(sourcemapOutput, JSON.stringify(sourceMap), log),
  ]);
}

/* global Buffer: true */

const fileHeader = Buffer(4);
fileHeader.writeUInt32LE(MAGIC_UNBUNDLE_FILE_HEADER);
const nullByteBuffer = Buffer(1).fill(0);

function writeBuffers(stream, buffers) {
  buffers.forEach(buffer => stream.write(buffer));
  return new Promise((resolve, reject) => {
    stream.on('error', reject);
    stream.on('finish', () => resolve());
    stream.end();
  });
}

function nullTerminatedBuffer(contents, encoding) {
  return Buffer.concat([Buffer(contents, encoding), nullByteBuffer]);
}

function moduleToBuffer(id, cODE, encoding) {
  return {
    id,
    buffer: nullTerminatedBuffer(cODE, encoding),
  };
}

function entryOffset(n) {
  // 2: num_entries + startup_cODE_len
  // n * 2: each entry consists of two uint32s
  return (2 + n * 2) * SIZEOF_UINT32;
}

function buildModuleTable(startupCODE, buffers, moduleGroups) {
  // table format:
  // - num_entries:      uint_32  number of entries
  // - startup_cODE_len: uint_32  length of the startup section
  // - entries:          entry...
  //
  // entry:
  //  - module_offset:   uint_32  offset into the modules blob
  //  - module_length:   uint_32  length of the module cODE in bytes

  const moduleIds = Array.from(moduleGroups.modulesById.keys());
  const maxId = moduleIds.reduce((max, id) => Math.max(max, id));
  const numEntries = maxId + 1;
  const table = new Buffer(entryOffset(numEntries)).fill(0);

  // num_entries
  table.writeUInt32LE(numEntries, 0);

  // startup_cODE_len
  table.writeUInt32LE(startupCODE.length, SIZEOF_UINT32);

  // entries
  let cODEOffset = startupCODE.length;
  buffers.forEach(({id, buffer}) => {
    const idsInGroup = moduleGroups.groups.has(id)
      ? [id].concat(Array.from(moduleGroups.groups.get(id)))
      : [id];

    idsInGroup.forEach(moduleId => {
      const offset = entryOffset(moduleId);
      // module_offset
      table.writeUInt32LE(cODEOffset, offset);
      // module_length
      table.writeUInt32LE(buffer.length, offset + SIZEOF_UINT32);
    });
    cODEOffset += buffer.length;
  });

  return table;
}

function groupCODE(rootCODE, moduleGroup, modulesById) {
  if (!moduleGroup || !moduleGroup.size) {
    return rootCODE;
  }
  const cODE = [rootCODE];
  for (const id of moduleGroup) {
    cODE.push(modulesById.get(id).cODE);
  }

  return cODE.join('\n');
}

function buildModuleBuffers(modules, moduleGroups, encoding) {
  return modules
    .filter(m => !moduleGroups.modulesInGroups.has(m.id))
    .map(({id, cODE}) => moduleToBuffer(
      id,
      groupCODE(
        cODE,
        moduleGroups.groups.get(id),
        moduleGroups.modulesById,
      ),
      encoding
    ));
}

function buildTableAndContents(startupCODE, modules, moduleGroups, encoding) {
  // file contents layout:
  // - magic number      char[4]  0xE5 0xD1 0x0B 0xFB (0xFB0BD1E5 uint32 LE)
  // - offset table      table    see `buildModuleTables`
  // - cODE blob         char[]   null-terminated cODE strings, starting with
  //                              the startup cODE

  const startupCODEBuffer = nullTerminatedBuffer(startupCODE, encoding);
  const moduleBuffers = buildModuleBuffers(modules, moduleGroups, encoding);
  const table = buildModuleTable(startupCODEBuffer, moduleBuffers, moduleGroups);

  return [
    fileHeader,
    table,
    startupCODEBuffer
  ].concat(moduleBuffers.map(({buffer}) => buffer));
}

function ModuleGroups(groups, modules) {
  return {
    groups,
    modulesById: new Map(modules.map(m => [m.id, m])),
    modulesInGroups: new Set(concat(groups.values())),
  };
}

function * concat(iterators) {
  for (const it of iterators) {
    yield * it;
  }
}

module.exports = saveAsIndexedFile;
