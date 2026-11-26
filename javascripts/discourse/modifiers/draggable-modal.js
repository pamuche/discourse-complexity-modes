import { modifier } from "ember-modifier";

// Lets the user drag the surrounding DModal by its header, so the page
// behind it stays visible while rules are being edited.
export default modifier((element) => {
  const container = element.closest(".d-modal__container");
  const header = container?.querySelector(".d-modal__header");
  if (!container || !header) {
    return;
  }

  let startX, startY, baseX, baseY;
  let offsetX = 0;
  let offsetY = 0;

  const onMove = (e) => {
    offsetX = baseX + e.clientX - startX;
    offsetY = baseY + e.clientY - startY;
    container.style.translate = `${offsetX}px ${offsetY}px`;
  };

  const onUp = () => {
    header.classList.remove("--dragging");
    document.removeEventListener("pointermove", onMove);
    document.removeEventListener("pointerup", onUp);
  };

  const onDown = (e) => {
    if (e.button !== 0 || e.target.closest("button, a, input")) {
      return;
    }
    e.preventDefault();
    startX = e.clientX;
    startY = e.clientY;
    baseX = offsetX;
    baseY = offsetY;
    header.classList.add("--dragging");
    document.addEventListener("pointermove", onMove);
    document.addEventListener("pointerup", onUp);
  };

  header.classList.add("complexity-modes-config__drag-handle");
  header.addEventListener("pointerdown", onDown);

  return () => {
    onUp();
    header.removeEventListener("pointerdown", onDown);
  };
});
