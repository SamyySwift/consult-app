import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';

/** Tracks an element's rendered size. Attach the returned ref to it. */
export function useElementSize() {
  const [el, setEl] = useState(null);
  const [size, setSize] = useState({ width: 0, height: 0 });

  useLayoutEffect(() => {
    if (!el) return;
    const update = () =>
      setSize((prev) =>
        prev.width === el.offsetWidth && prev.height === el.offsetHeight
          ? prev
          : { width: el.offsetWidth, height: el.offsetHeight },
      );
    update();
    const observer = new ResizeObserver(update);
    observer.observe(el);
    return () => observer.disconnect();
  }, [el]);

  return [setEl, size];
}

/**
 * Position of the selected item among its siblings, for a capsule that slides
 * under it (the client's segmented control and nav bar). Register each item
 * with `register(key)`; their common parent must be positioned.
 */
export function useSlidingIndicator(active) {
  const items = useRef(new Map());
  const [box, setBox] = useState(null);

  const measure = useCallback(() => {
    const el = items.current.get(active);
    setBox((prev) => {
      if (!el) return null;
      const next = { left: el.offsetLeft, top: el.offsetTop, width: el.offsetWidth, height: el.offsetHeight };
      const same = prev && Object.keys(next).every((k) => prev[k] === next[k]);
      return same ? prev : next;
    });
  }, [active]);

  // Labels change width as counts update, so re-measure after every render
  useLayoutEffect(measure);

  // …and when fonts load or the window resizes
  useEffect(() => {
    const observer = new ResizeObserver(measure);
    items.current.forEach((el) => observer.observe(el));
    return () => observer.disconnect();
  }, [measure]);

  const register = useCallback(
    (key) => (el) => {
      if (el) items.current.set(key, el);
      else items.current.delete(key);
    },
    [],
  );

  return { register, box };
}
