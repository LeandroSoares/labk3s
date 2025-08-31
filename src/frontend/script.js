// Função para buscar uma piada do backend
async function fetchJoke() {
  try {
    document.getElementById("joke-text").textContent = "Carregando piada...";
    console.log("Tentando buscar piada em /api/jokes/random");
    
    // Iniciar o span de telemetria para rastrear a requisição
    const span = window.telemetry ? window.telemetry.startSpan('fetch_joke', { 
      operation: 'fetch_random_joke' 
    }) : null;
    
    const response = await fetch("/api/jokes/random", {
      headers: {
        'X-Trace-ID': `frontend-${Date.now()}`
      }
    });
    console.log("Resposta recebida:", response.status);
    
    if (span) {
      window.telemetry.addEvent(span, 'fetch_response', { 
        status: response.status,
        ok: response.ok
      });
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Resposta de erro:", errorText);

      if (response.status === 404) {
        document.getElementById("joke-text").textContent = "Sem piadas hoje...";
      } else {
        throw new Error(`Erro ao buscar piada: ${response.status}`);
      }
      return;
    }

    const data = await response.json();
    document.getElementById("joke-text").textContent =
      data.text || "Sem piadas hoje...";
      
    // Finalizar o span de telemetria
    if (span) {
      window.telemetry.endSpan(span);
    }
  } catch (error) {
    console.error("Erro ao buscar piada:", error);
    document.getElementById("joke-text").textContent =
      "Erro ao carregar piada. Tente novamente.";
      
    // Finalizar o span em caso de erro
    if (span) {
      window.telemetry.addEvent(span, 'error', { message: error.message });
      window.telemetry.endSpan(span);
    }
  }
}

// Função para adicionar uma nova piada
async function addJoke(jokeText) {
  try {
    console.log("Tentando adicionar piada em /api/jokes");
    
    const response = await fetch("/api/jokes", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        'X-Trace-ID': `frontend-${Date.now()}`
      },
      body: JSON.stringify({ text: jokeText })
    });

    console.log("Resposta recebida:", response.status);

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Resposta de erro:", errorText);

      let errorMessage = `Erro HTTP: ${response.status}`;
      try {
        const errorData = JSON.parse(errorText);
        errorMessage = errorData.error || errorMessage;
      } catch {
        // Ignora erro de parsing JSON
      }
      throw new Error(errorMessage);
    }

    const result = await response.json();
    return result;
  } catch (error) {
    console.error("Erro ao adicionar piada:", error);
    throw error;
  }
}

// Configuração do modal
const modal = document.getElementById("addJokeModal");
const addJokeBtn = document.getElementById("add-joke-btn");
const closeBtn = document.querySelector(".close");
const form = document.getElementById("addJokeForm");
const successMessage = document.getElementById("success-message");

// Abrir o modal
addJokeBtn.addEventListener("click", () => {
  modal.classList.remove("hidden");
  successMessage.classList.add("hidden");
  document.getElementById("jokeText").value = "";
});

// Fechar o modal
closeBtn.addEventListener("click", () => {
  modal.classList.add("hidden");
});

// Fechar o modal clicando fora dele
window.addEventListener("click", event => {
  if (event.target === modal) {
    modal.classList.add("hidden");
  }
});

// Enviar o formulário
form.addEventListener("submit", async e => {
  e.preventDefault();
  const jokeText = document.getElementById("jokeText").value.trim();

  if (!jokeText) {
    alert("Por favor, digite uma piada!");
    return;
  }

  try {
    await addJoke(jokeText);
    successMessage.classList.remove("hidden");
    document.getElementById("jokeText").value = "";

    // Fechar o modal após 2 segundos
    setTimeout(() => {
      modal.classList.add("hidden");
      // Buscar uma nova piada para mostrar a que acabou de ser adicionada
      fetchJoke();
    }, 2000);
  } catch (error) {
    alert("Erro ao adicionar piada: " + error.message);
  }
});

// Buscar uma piada ao carregar a página
window.addEventListener("DOMContentLoaded", fetchJoke);

// Configurar o botão para buscar nova piada
document.getElementById("new-joke-btn").addEventListener("click", fetchJoke);
