// Lets the user click an element on the page. Resolves with the element, or
// null when cancelled with Escape / right click.

const PICKING_CLASS = "complexity-modes-picking";

export function pickElement({ ignore = () => false } = {}) {
  return new Promise((resolve) => {
    const highlight = document.createElement("div");
    highlight.className = "complexity-modes-picker-highlight";
    document.body.appendChild(highlight);
    document.documentElement.classList.add(PICKING_CLASS);

    let current = null;

    const target = (event) => {
      const el = document.elementFromPoint(event.clientX, event.clientY);
      return el && !ignore(el) && el !== highlight ? el : null;
    };

    const onMove = (event) => {
      current = target(event);
      if (!current) {
        highlight.style.display = "none";
        return;
      }
      const r = current.getBoundingClientRect();
      Object.assign(highlight.style, {
        display: "block",
        top: `${r.top}px`,
        left: `${r.left}px`,
        width: `${r.width}px`,
        height: `${r.height}px`,
      });
    };

    const finish = (result) => {
      document.removeEventListener("mousemove", onMove, true);
      document.removeEventListener("click", onClick, true);
      document.removeEventListener("contextmenu", onCancel, true);
      document.removeEventListener("keydown", onKey, true);
      highlight.remove();
      document.documentElement.classList.remove(PICKING_CLASS);
      resolve(result);
    };

    const onClick = (event) => {
      event.preventDefault();
      event.stopPropagation();
      finish(target(event));
    };

    const onCancel = (event) => {
      event.preventDefault();
      finish(null);
    };

    const onKey = (event) => {
      if (event.key === "Escape") {
        event.preventDefault();
        event.stopPropagation();
        finish(null);
      }
    };

    document.addEventListener("mousemove", onMove, true);
    document.addEventListener("click", onClick, true);
    document.addEventListener("contextmenu", onCancel, true);
    document.addEventListener("keydown", onKey, true);
  });
}
