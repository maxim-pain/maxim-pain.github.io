/* Small progressive enhancements. No dependencies, no build step.
   Everything here degrades to a perfectly usable page if JS is off. */
(function () {
  "use strict";

  var root = document.documentElement;

  /* ── active nav item ─────────────────────────────────────────────────── */
  var here = location.pathname.split("/").pop() || "index.html";
  Array.prototype.forEach.call(document.querySelectorAll(".nav-links a"), function (a) {
    if (a.getAttribute("href") === here) a.setAttribute("aria-current", "page");
  });

  /* ── theme toggle: dark ⇄ light, remembered ───────────────────────────
     The head of each page already applied the stored choice before paint;
     this only wires the button and keeps the icon in sync. */
  function prefersLight() {
    return window.matchMedia && window.matchMedia("(prefers-color-scheme: light)").matches;
  }
  function currentTheme() {
    return root.dataset.theme || (prefersLight() ? "light" : "dark");
  }
  function paintIcon() {
    var icon = document.querySelector("[data-theme-icon]");
    if (icon) icon.textContent = currentTheme() === "light" ? "☾" : "☀";
  }
  var toggle = document.querySelector("[data-theme-toggle]");
  if (toggle) {
    paintIcon();
    toggle.addEventListener("click", function () {
      var next = currentTheme() === "light" ? "dark" : "light";
      root.dataset.theme = next;
      try { localStorage.setItem("theme", next); } catch (e) { /* private mode */ }
      paintIcon();
    });
  }

  /* ── current year in the footer ───────────────────────────────────────── */
  Array.prototype.forEach.call(document.querySelectorAll("[data-year]"), function (el) {
    el.textContent = new Date().getFullYear();
  });

  /* ── print button (resume) ────────────────────────────────────────────── */
  var printBtn = document.querySelector("[data-print]");
  if (printBtn) printBtn.addEventListener("click", function () { window.print(); });

  /* ── copy-to-clipboard for the forwardable block ──────────────────────── */
  var copyBtn = document.querySelector("[data-copy]");
  var fwd = document.querySelector("[data-fwd]");
  if (copyBtn && fwd && navigator.clipboard) {
    copyBtn.addEventListener("click", function () {
      navigator.clipboard.writeText(fwd.innerText).then(function () {
        var was = copyBtn.textContent;
        copyBtn.textContent = "Copied";
        setTimeout(function () { copyBtn.textContent = was; }, 1600);
      });
    });
  } else if (copyBtn) {
    copyBtn.style.display = "none";   /* no clipboard API — the text is still selectable */
  }

  /* ── reveal on scroll ─────────────────────────────────────────────────── */
  var targets = document.querySelectorAll(".reveal");
  var reduced = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (reduced || !("IntersectionObserver" in window)) {
    Array.prototype.forEach.call(targets, function (el) { el.classList.add("in"); });
    return;
  }

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      var el = entry.target;
      setTimeout(function () { el.classList.add("in"); }, Number(el.dataset.delay || 0));
      io.unobserve(el);
    });
  }, { threshold: 0.1, rootMargin: "0px 0px -6% 0px" });

  Array.prototype.forEach.call(targets, function (el) { io.observe(el); });
})();
