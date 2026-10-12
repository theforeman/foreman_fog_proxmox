import React from 'react';
import { fireEvent, render } from '@testing-library/react';
import { ProxmoxBiosProvider } from '../ProxmoxBiosContext';
import ProxmoxServerStorage from '../ProxmoxServer/ProxmoxServerStorage';

jest.mock('foremanReact/redux/API', () => ({
  API: {
    get: jest.fn(),
  },
}));

const storages = [
  {
    storage: 'local-lvm',
    node_id: 'node-a',
    content: 'images',
    avail: 100,
    used: 20,
    total: 120,
    shared: 0,
  },
  {
    storage: 'shared',
    node_id: 'node-a',
    content: 'images',
    avail: 500,
    used: 100,
    total: 600,
    shared: 1,
  },
  {
    storage: 'local-lvm',
    node_id: 'node-b',
    content: 'images',
    avail: 200,
    used: 30,
    total: 230,
    shared: 0,
  },
  {
    storage: 'shared',
    node_id: 'node-b',
    content: 'images',
    avail: 500,
    used: 100,
    total: 600,
    shared: 1,
  },
  {
    storage: 'node-b-only',
    node_id: 'node-b',
    content: 'images',
    avail: 300,
    used: 40,
    total: 340,
    shared: 0,
  },
];

describe.each([
  ['host', false, 'host[compute_attributes]'],
  ['profile', true, 'compute_attribute[vm_attrs]'],
])('%s hard disk storage choices', (_kind, fromProfile, paramScope) => {
  const field = (name, value) => ({
    name: `${paramScope}[volumes_attributes][0][${name}]`,
    value,
  });
  const renderStorage = (storageValue = 'local-lvm', nodeId = 'node-a') => {
    const storage = [
      {
        name: 'hard_disk',
        value: {
          id: field('id', 'virtio0'),
          controller: field('controller', 'virtio'),
          device: field('device', '0'),
          storage: field('storage', storageValue),
          _delete: field('_delete', '0'),
        },
      },
    ];
    const component = selectedNode => (
      <form>
        <ProxmoxBiosProvider>
          <ProxmoxServerStorage
            storage={storage}
            storages={storages}
            fromProfile={fromProfile}
            paramScope={paramScope}
            nodeId={selectedNode}
          />
        </ProxmoxBiosProvider>
      </form>
    );
    const view = render(component(nodeId));
    const form = view.container.querySelector('form');
    const select = view.container.querySelector(
      `select[name="${field('storage').name}"]`
    );
    return {
      ...view,
      form,
      select,
      changeNode: selectedNode => view.rerender(component(selectedNode)),
      submittedStorage: () => new FormData(form).get(field('storage').name),
    };
  };

  it('filters by the selected node and refreshes after node changes', () => {
    const { select, changeNode, submittedStorage } = renderStorage();
    const values = () => Array.from(select.options, option => option.value);

    expect(values()).toEqual(['local-lvm', 'shared']);
    expect(select.value).toBe('local-lvm');
    expect(submittedStorage()).toBe('local-lvm');
    expect(select.options[0].textContent).toBe(
      'local-lvm (free: 100 B, used: 20 B, total: 120 B)'
    );

    changeNode('node-b');

    expect(values()).toEqual(['local-lvm', 'shared', 'node-b-only']);
    expect(select.value).toBe('local-lvm');
    expect(submittedStorage()).toBe('local-lvm');
    expect(select.options[0].textContent).toBe(
      'local-lvm (free: 200 B, used: 30 B, total: 230 B)'
    );

    changeNode('node-a');
    expect(values()).toEqual(['local-lvm', 'shared']);
  });

  it.each(['node-a', 'node-with-no-storage'])(
    'preserves an unavailable selection on %s and blocks saving until the original node is restored',
    nodeId => {
      const {
        select,
        form,
        changeNode,
        submittedStorage,
        queryByText,
      } = renderStorage('node-b-only', 'node-b');

      expect(form.checkValidity()).toBe(true);
      changeNode(nodeId);

      expect(select.value).toBe('node-b-only');
      expect(select.selectedOptions[0].textContent).toBe(
        'node-b-only (unavailable)'
      );
      expect(submittedStorage()).toBe('node-b-only');
      expect(select.validationMessage).toBe(
        'Select an available resource or change the node or storage.'
      );
      expect(
        queryByText(
          'Select an available resource or change the node or storage.'
        )
      ).toBeInTheDocument();
      expect(select).toHaveAttribute('aria-invalid', 'true');
      expect(form.checkValidity()).toBe(false);

      changeNode('node-b');

      expect(select.value).toBe('node-b-only');
      expect(select.selectedOptions[0].textContent).not.toContain(
        'unavailable'
      );
      expect(submittedStorage()).toBe('node-b-only');
      expect(select.validationMessage).toBe('');
      expect(
        queryByText(
          'Select an available resource or change the node or storage.'
        )
      ).not.toBeInTheDocument();
      expect(form.checkValidity()).toBe(true);
    }
  );

  it('accepts an explicit replacement and retains it across node changes', () => {
    const { select, form, changeNode, submittedStorage } = renderStorage(
      'node-b-only',
      'node-b'
    );
    changeNode('node-a');
    expect(form.checkValidity()).toBe(false);

    fireEvent.change(select, { target: { value: 'shared' } });

    expect(select.value).toBe('shared');
    expect(submittedStorage()).toBe('shared');
    expect(Array.from(select.options, option => option.value)).toEqual([
      'local-lvm',
      'shared',
    ]);
    expect(select.validationMessage).toBe('');
    expect(form.checkValidity()).toBe(true);
    changeNode('node-b');
    expect(select.value).toBe('shared');
    expect(submittedStorage()).toBe('shared');
  });

  it('does not block saving when the disk with unavailable storage is removed', () => {
    const { select, form, getByRole } = renderStorage('node-b-only', 'node-a');
    expect(form.checkValidity()).toBe(false);

    fireEvent.click(getByRole('button', { name: '' }));

    expect(select.validationMessage).toBe('');
    expect(form.checkValidity()).toBe(true);
    expect(new FormData(form).get(field('_delete').name)).toBe('1');
  });
});
