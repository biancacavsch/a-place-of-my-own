// ===== CARREGAR POSTS DO BLOG =====

// async = função para aguardar funções demoradas
async function carregarPosts() {
  const container = document.getElementById("lista-posts");

  try {
    // fetch = buscar um arquivo (no caso, o posts.json)
    // await = espera a resposta chegar
    const resposta = await fetch("data/posts.json");

    if (!resposta.ok) {
      throw new Error("Erro ao carregar posts");
    }

    // .json() = converte a resposta pra array/dicionário Python (objeto JS)
    const posts = await resposta.json();

    // Se não tem posts
    if (posts.length === 0) {
      container.innerHTML = "<p>Nenhum post publicado ainda.</p>";
      return;
    }

    // Montar o HTML de cada post
    // map = transforma cada item da lista em HTML
    // join("") = junta tudo numa string só
    const htmlPosts = posts.map(post => {
      // Criar as tags HTML
      const tagsHtml = post.tags
        .map(tag => `<span class="tag">${tag}</span>`)
        .join("");

      return `
        <article class="post">
          <h2>${post.titulo}</h2>
          <p class="post-data">${post.data}</p>
          <p class="post-resumo">${post.resumo}</p>
          ${post.imagem ? `<img src="${post.imagem}" alt="${post.titulo}">` : ""}
          <div class="post-tags">${tagsHtml}</div>
        </article>
      `;
    }).join("");

    container.innerHTML = htmlPosts;

  } catch (erro) {
    // Se algo der errado (arquivo não existe, etc.)
    container.innerHTML = `<p>❌ Erro ao carregar os posts: ${erro.message}</p>`;
  }
}

// Executar quando a página carregar
carregarPosts();