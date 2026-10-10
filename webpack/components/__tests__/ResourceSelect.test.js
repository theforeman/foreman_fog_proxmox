import React from 'react';
import { fireEvent, render } from '@testing-library/react';
import ResourceSelect, {
  ResourceAvailabilityContext,
} from '../common/ResourceSelect';

const options = [{ value: 'available', label: 'Available' }];

describe('resource selections', () => {
  it.each(['ready', 'loading', 'error'])(
    'preserves submitted selections with %s metadata',
    availability => {
      const { container } = render(
        <form>
          <ResourceAvailabilityContext.Provider value={availability}>
            <ResourceSelect
              name="resource"
              value="saved"
              options={options}
              onChange={jest.fn()}
            />
          </ResourceAvailabilityContext.Provider>
        </form>
      );
      const select = container.querySelector('select');
      expect(select.value).toBe('saved');
      expect(
        new FormData(container.querySelector('form')).get('resource')
      ).toBe('saved');
      expect(select.checkValidity()).toBe(false);
      expect(
        select.selectedOptions[0].textContent.includes('unavailable')
      ).toBe(availability === 'ready');
      expect(select.validationMessage).toContain(
        {
          ready: 'Select an available',
          loading: 'still loading',
          error: 'could not be checked',
        }[availability]
      );
    }
  );

  it('clears invalidity after recovery and distinguishes optional blanks from required ones', () => {
    const component = (value, required = false) => (
      <ResourceSelect
        name="resource"
        value={value}
        options={options}
        onChange={jest.fn()}
        required={required}
      />
    );
    const { container, rerender } = render(component('saved'));
    const select = container.querySelector('select');
    expect(select.checkValidity()).toBe(false);
    rerender(component('available'));
    expect(select.checkValidity()).toBe(true);
    rerender(component(''));
    expect(select.value).toBe('');
    expect(select.checkValidity()).toBe(true);
    rerender(component('', true));
    expect(select.checkValidity()).toBe(false);
  });

  it('does not invalidate inactive or disabled resources', () => {
    const { container, rerender } = render(
      <ResourceSelect
        value="saved"
        options={[]}
        onChange={jest.fn()}
        active={false}
      />
    );
    const select = container.querySelector('select');
    expect(select.validationMessage).toBe('');
    rerender(
      <ResourceSelect
        value="saved"
        options={[]}
        onChange={jest.fn()}
        disabled
      />
    );
    expect(select.validationMessage).toBe('');
  });

  it('does not report an empty resource list as unavailable while loading', () => {
    const { queryByText } = render(
      <ResourceSelect
        value="saved"
        options={[]}
        availability="loading"
        error="No resources available"
        onChange={jest.fn()}
      />
    );
    expect(queryByText('No resources available')).not.toBeInTheDocument();
    expect(
      queryByText('Resource availability is still loading. Please wait.')
    ).toBeInTheDocument();
  });

  it('uses an initial default only when requested and never replaces a saved value', () => {
    const component = value => (
      <ResourceSelect
        value={value}
        options={options}
        onChange={jest.fn()}
        defaultToFirst
      />
    );
    const { container, rerender } = render(component(''));
    expect(container.querySelector('select').value).toBe('available');
    rerender(component('saved'));
    expect(container.querySelector('select').value).toBe('saved');
  });

  it('reports explicit choices through the original change handler', () => {
    const changes = [];
    const { container } = render(
      <ResourceSelect
        name="resource"
        value="saved"
        options={options}
        onChange={event => changes.push(event.target.value)}
      />
    );
    fireEvent.change(container.querySelector('select'), {
      target: { value: 'available' },
    });
    expect(changes).toEqual(['available']);
  });

  it.each(['ready', 'loading', 'error', 'parent'])(
    'allows optional blanks but not required blanks during %s',
    availability => {
      const component = required => (
        <ResourceSelect
          availability={availability}
          options={[]}
          onChange={jest.fn()}
          required={required}
        />
      );
      const { container, rerender } = render(component(false));
      const select = container.querySelector('select');
      expect(select.checkValidity()).toBe(true);
      expect(container.querySelector('.has-error')).toBeNull();
      rerender(component(true));
      const message =
        availability === 'error'
          ? 'Resource availability could not be checked. Reload the form to retry.'
          : 'Select a resource.';
      expect(select.validationMessage).toBe(message);
      expect(
        container.querySelector('.has-error .error-message')
      ).toHaveTextContent(message);
    }
  );

  it.each([{ active: false }, { disabled: true }])(
    'does not show lookup errors for an inactive empty required field (%j)',
    props => {
      const { container } = render(
        <ResourceSelect
          {...props}
          required
          availability="error"
          options={[]}
          onChange={jest.fn()}
        />
      );
      expect(container.querySelector('select').validationMessage).toBe('');
      expect(container.querySelector('.has-error')).toBeNull();
    }
  );

  it('preserves selections without applying defaults until a node is selected', () => {
    const component = availability => (
      <ResourceAvailabilityContext.Provider value={availability}>
        <ResourceSelect
          name="storage"
          value="saved"
          options={[]}
          onChange={jest.fn()}
        />
        <ResourceSelect
          name="new-storage"
          options={options}
          defaultToFirst
          onChange={jest.fn()}
        />
      </ResourceAvailabilityContext.Provider>
    );
    const { container, rerender } = render(component('parent'));
    const storage = container.querySelector('[name="storage"]');
    expect(storage.value).toBe('saved');
    expect(storage.selectedOptions[0].textContent).toBe('saved');
    expect(storage.validationMessage).toBe(
      'Select a node to check resource availability.'
    );
    expect(container.querySelector('[name="new-storage"]').value).toBe('');
    rerender(component('ready'));
    expect(storage.selectedOptions[0].textContent).toBe('saved (unavailable)');
    expect(container.querySelector('[name="new-storage"]').value).toBe(
      'available'
    );
  });
});
