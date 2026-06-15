/* Topbar scroll indicator */
const topbar = document.getElementById('topbar');
function onScroll() {
  topbar.classList.toggle('scrolled', window.scrollY > 12);
}
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

/* Fade-in on scroll */
const io = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      e.target.classList.add('visible');
      io.unobserve(e.target);
    }
  });
}, { threshold: 0.08 });
document.querySelectorAll('.fade-in').forEach(el => io.observe(el));
