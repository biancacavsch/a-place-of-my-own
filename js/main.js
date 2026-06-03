// ===== TROCA DE TEMA (DARK / LIGHT) =====

// 1. Pegar os elementos que precisamos
const botaoTema = document.getElementById("toggle-tema");
const html = document.documentElement; // <html>

// 2. Verificar se já existe tema salvo no navegador
const temaSalvo = localStorage.getItem("tema");

if (temaSalvo) {
  // Se o usuário já escolheu um tema antes, aplica ele
  html.setAttribute("data-theme", temaSalvo);
  botaoTema.textContent = temaSalvo === "dark" ? "☀️" : "🌙";
} else {
  // Tema padrão: escuro
  html.setAttribute("data-theme", "dark");
  botaoTema.textContent = "☀️";
}

// 3. Função que alterna o tema
function alternarTema() {
  const temaAtual = html.getAttribute("data-theme");

  if (temaAtual === "dark") {
    html.setAttribute("data-theme", "light");
    botaoTema.textContent = "🌙";
    localStorage.setItem("tema", "light");
  } else {
    html.setAttribute("data-theme", "dark");
    botaoTema.textContent = "☀️";
    localStorage.setItem("tema", "dark");
  }
}

// 4. Quando clicar no botão, chama a função
botaoTema.addEventListener("click", alternarTema);

// ===== ANIMAÇÃO DE SCROLL (FADE-IN) =====
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add("visivel");
    }
  });
}, { threshold: 0.15 });

document.querySelectorAll(".fade-in").forEach(el => observer.observe(el));

// ===== EFEITO DE DIGITAÇÃO NO HERO =====
const titulo = document.querySelector(".hero h1");
if (titulo) {
  const texto = titulo.textContent;
  titulo.textContent = "";
  const span = document.createElement("span");
  span.textContent = texto;
  titulo.appendChild(span);
}

// ===== DESTACAR LINK ATIVO NO MENU =====
const links = document.querySelectorAll(".menu a");
const caminho = window.location.pathname.split("/").pop() || "index.html";
links.forEach(link => {
  if (link.getAttribute("href") === caminho) {
    link.classList.add("ativo");
  }
});