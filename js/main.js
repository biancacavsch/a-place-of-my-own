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

// ===== DESTACAR LINK ATIVO NO MENU =====
// O JS não precisa mais fazer isso porque colocamos class="ativo"
// manualmente em cada página HTML.
// Mas se quiséssemos fazer automático, seria com window.location.