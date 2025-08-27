// Função para buscar uma piada do backend
async function fetchJoke() {
  // Inicia um span de telemetria
  const span = window.telemetry ? window.telemetry.startSpan('fetch_joke', { action: 'fetch_random_joke' }) : null;
  
  try {
    document.getElementById("joke-text").textContent = "Carregando piada...";
    console.log("Tentando buscar piada em /api/jokes/random");
    
    if (span) {
      window.telemetry.addEvent(span, 'fetch_start', { endpoint: '/api/jokes/random' });
    }
    
    const response = await fetch("/api/jokes/random", {
      headers: {
        // Adiciona um cabeçalho para correlação de tracing
        'X-Trace-ID': span ? span.attributes.traceId || `frontend-${Date.now()}` : `frontend-${Date.now()}`
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
      
      if (span) {
        window.telemetry.addEvent(span, 'fetch_error', { 
          status: response.status,
          error: errorText
        });
      }

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
      
    if (span) {
      window.telemetry.addEvent(span, 'joke_displayed', { 
        joke_id: data.id,
        joke_length: data.text.length
      });
    }
  } catch (error) {
    console.error("Erro ao buscar piada:", error);
    document.getElementById("joke-text").textContent =
      "Erro ao carregar piada. Tente novamente.";
      
    if (span) {
      window.telemetry.addEvent(span, 'fetch_exception', { 
        error_message: error.message
      });
    }
  } finally {
    if (span) {
      window.telemetry.endSpan(span);
    }
  }
}

// Função para adicionar uma nova piada
async function addJoke(jokeText) {
  // Inicia um span de telemetria
  const span = window.telemetry ? window.telemetry.startSpan('add_joke', { 
    action: 'add_joke',
    joke_length: jokeText.length 
  }) : null;
  
  try {
    console.log("Tentando adicionar piada em /api/jokes");
    
    if (span) {
      window.telemetry.addEvent(span, 'add_joke_start', { 
        endpoint: '/api/jokes',
        method: 'POST'
      });
    }
    
    const response = await fetch("/api/jokes", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // Adiciona um cabeçalho para correlação de tracing
        'X-Trace-ID': span ? span.attributes.traceId || `frontend-${Date.now()}` : `frontend-${Date.now()}`
      },
      body: JSON.stringify({ text: jokeText })
    });

    console.log("Resposta recebida:", response.status);
    
    if (span) {
      window.telemetry.addEvent(span, 'add_joke_response', { 
        status: response.status,
        ok: response.ok
      });
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Resposta de erro:", errorText);
      
      if (span) {
        window.telemetry.addEvent(span, 'add_joke_error', { 
          status: response.status,
          error: errorText
        });
      }

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
    
    if (span) {
      window.telemetry.addEvent(span, 'joke_added', { 
        joke_id: result.id
      });
    }
    
    return result;
  } catch (error) {
    console.error("Erro ao adicionar piada:", error);
    
    if (span) {
      window.telemetry.addEvent(span, 'add_joke_exception', { 
        error_message: error.message
      });
    }
    
    throw error;
  } finally {
    if (span) {
      window.telemetry.endSpan(span);
    }
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
