/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict
 * @format
 */

/*
There's no way for us to automatically reference the transform function types generated by `genTransformNodeTypes`
*/

import {
  HermesESTreeJSON,
  formatAndWriteDistArtifact,
} from './utils/scriptUtils';

const imports: Array<string> = [];
const replaceSignatures: Array<string> = [];

for (const node of HermesESTreeJSON) {
  if (node.name === 'Program') {
    // cloning the entire program isn't supported
    continue;
  }

  imports.push(node.name);

  const propTypes = `${node.name}Props`;
  replaceSignatures.push(
    `(
      node: ${node.name},
      newProps?: $Shape<${propTypes}>,
    ): DetachedNode<${node.name}>`,
    `(
      node: ?${node.name},
      newProps?: $Shape<${propTypes}>,
    ): DetachedNode<${node.name}> | null`,
  );
}

const fileContents = `\
import type {
${imports.join(',\n')}
} from 'hermes-estree';
import type {
${imports.map(i => `${i}Props`).join(',\n')}
} from './node-types';
import type {DetachedNode} from '../detachedNode';

export type TransformCloneSignatures = {
${replaceSignatures.join(',\n')},
};
`;

formatAndWriteDistArtifact({
  code: fileContents,
  package: 'hermes-transform',
  filename: 'TransformCloneSignatures.js.flow',
  subdirSegments: ['generated'],
  flow: 'strict-local',
});
