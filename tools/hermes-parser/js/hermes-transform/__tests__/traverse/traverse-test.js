/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow strict-local
 * @format
 */

'use strict';

import {parseForESLint} from 'hermes-eslint';
import {traverse} from '../../src/traverse/traverse';

describe('traverse', () => {
  it('accepts and calls selectors', () => {
    const {ast, scopeManager} = parseForESLint('const x = 1;');

    const visitedNodes = [];
    traverse(ast, scopeManager, () => ({
      Program(node) {
        visitedNodes.push(node.type);
      },
      VariableDeclaration(node) {
        visitedNodes.push(node.type);
      },
      'Literal[value=1]:exit'(node) {
        visitedNodes.push(node.type);
      },
    }));

    expect(visitedNodes).toEqual(['Program', 'VariableDeclaration', 'Literal']);
  });

  it('visits the AST in the correct order - traversed as defined by the visitor keys', () => {
    const {ast, scopeManager} = parseForESLint('const x = 1;');

    const starNodes = [];
    traverse(ast, scopeManager, () => ({
      '*'(node) {
        starNodes.push(node.type);
      },
    }));

    expect(starNodes).toEqual([
      'Program',
      'VariableDeclaration',
      'VariableDeclarator',
      'Identifier',
      'Literal',
    ]);
  });

  it('sets the parent pointers', () => {
    const {ast, scopeManager} = parseForESLint('const x = 1;');

    expect(ast.body[0]).not.toHaveProperty('parent');
    traverse(ast, scopeManager, () => ({
      '*'(node) {
        expect(node).toHaveProperty('parent');
        if (node.type === 'Program') {
          // eslint-disable-next-line jest/no-conditional-expect
          expect(node.parent).toBeNull();
        } else {
          // eslint-disable-next-line jest/no-conditional-expect
          expect(node.parent).toHaveProperty('type');
        }
      },
    }));
  });

  it('passes an immutable context object', () => {
    const {ast, scopeManager} = parseForESLint('const x = 1;');

    traverse(ast, scopeManager, context => ({
      Program() {
        expect(typeof context).toBe('object');
        expect(context).toHaveProperty('getScope');
        expect(() => {
          // $FlowExpectedError[cannot-write]
          context.getScope = () => {};
        }).toThrowError(/Cannot assign to read only property 'getScope'/);
      },
    }));
  });

  it('correctly handles scope analysis', () => {
    const {ast, scopeManager} = parseForESLint(`
      const x = 1;
      {
        function foo(x) {
          x + 1;
        }
      }
    `);

    traverse(ast, scopeManager, context => ({
      VariableDeclarator(node) {
        const declaredVariables = context.getDeclaredVariables(node);
        expect(declaredVariables).toHaveLength(1);
        expect(declaredVariables[0].name).toBe('x');
      },
      FunctionDeclaration(node) {
        const declaredVariables = context.getDeclaredVariables(node);
        expect(declaredVariables).toHaveLength(2);
        expect(declaredVariables[0].name).toBe('foo');
        expect(declaredVariables[1].name).toBe('x');
      },
      'BinaryExpression > Identifier.left'(node) {
        if (node.type !== 'Identifier') {
          return;
        }

        const variable = context.getBinding(node.name);
        expect(variable).not.toBeNull();
        if (variable != null) {
          // eslint-disable-next-line jest/no-conditional-expect
          expect(variable.name).toBe(node.name);
        }
      },
    }));
  });
});
