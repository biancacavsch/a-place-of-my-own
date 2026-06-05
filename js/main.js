(function() {
  const botaoTema = document.getElementById("toggle-tema");
  const html = document.documentElement;

  const temaSalvo = localStorage.getItem("tema") || "dark";
  html.setAttribute("data-theme", temaSalvo);
  if (botaoTema) {
    botaoTema.textContent = temaSalvo === "dark" ? "☀️" : "🌙";
  }

  window.alternarTema = function() {
    const atual = html.getAttribute("data-theme");
    const novo = atual === "dark" ? "light" : "dark";
    html.setAttribute("data-theme", novo);
    if (botaoTema) botaoTema.textContent = novo === "dark" ? "☀️" : "🌙";
    localStorage.setItem("tema", novo);
  };

  if (botaoTema) {
    botaoTema.addEventListener("click", window.alternarTema);
  }
})();