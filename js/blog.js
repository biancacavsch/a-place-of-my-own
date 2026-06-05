(async function() {
  const container = document.getElementById("lista-posts");
  const filtroContainer = document.getElementById("filtro-tags");
  const homeRepoCount = document.getElementById("repo-count");
  const homePostCount = document.getElementById("post-count");

  if (!container) return;

  try {
    const resposta = await fetch("data/posts.json");
    if (!resposta.ok) throw new Error("Erro ao carregar");
    const posts = await resposta.json();

    if (posts.length === 0) {
      container.innerHTML = "<p class='carregando'>Nenhum texto publicado ainda.</p>";
      return;
    }

    const todasTags = ["todas", ...new Set(posts.flatMap(p => p.tags))];
    const botoesExistentes = filtroContainer.querySelectorAll("button");
    if (botoesExistentes.length <= 1) {
      todasTags.slice(1).forEach(tag => {
        const btn = document.createElement("button");
        btn.textContent = tag;
        btn.dataset.filtro = tag;
        filtroContainer.appendChild(btn);
      });
    }

    function renderizar(filtro) {
      const filtrados = filtro === "todas"
        ? posts
        : posts.filter(p => p.tags.includes(filtro));

      container.innerHTML = filtrados.map(post => {
        const tagsHtml = post.tags.map(t => `<span class="tag">${t}</span>`).join("");
        return `
          <article class="post-completo">
            <div class="post-livro">
              <div class="post-livro-capa">${post.capa || "📖"}</div>
              <div class="post-livro-info">
                <h3>${post.autor || ""}</h3>
                <div class="autor">${post.nota || ""}</div>
                <div class="nota"></div>
              </div>
            </div>
            <h2>${post.titulo}</h2>
            <p class="post-data">${post.data}</p>
            <div class="post-tags">${tagsHtml}</div>
            <div class="post-corpo">${post.corpo || post.resumo || ""}</div>
          </article>
        `;
      }).join("");

      filtroContainer.querySelectorAll("button").forEach(b => {
        b.classList.toggle("ativo", b.dataset.filtro === filtro);
      });
    }

    filtroContainer.addEventListener("click", function(e) {
      if (e.target.tagName === "BUTTON") {
        renderizar(e.target.dataset.filtro);
      }
    });

    renderizar("todas");

    if (homePostCount) homePostCount.textContent = posts.length;

  } catch (erro) {
    container.innerHTML = `<p class='carregando'>Erro ao carregar textos.</p>`;
  }
})();