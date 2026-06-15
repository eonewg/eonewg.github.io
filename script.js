/* Topbar scroll indicator */
const topbar = document.getElementById('topbar');
function onScroll() {
  topbar.classList.toggle('scrolled', window.scrollY > 12);
}
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();
