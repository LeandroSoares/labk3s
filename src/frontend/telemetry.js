// telemetry.js - Configuração do OpenTelemetry para o frontend

// Definir a API de telemetria diretamente no escopo global
(function() {
  // Detecta se o navegador suporta a API de Tracing
  if (!window.PerformanceObserver || !window.PerformanceEntry || !window.PerformanceResourceTiming) {
    console.warn('Este navegador não suporta a API de Performance Timing.');
    return;
  }

  // Cria um objeto para rastreamento manual
  window.telemetry = {
    startSpan: function(name, attributes = {}) {
      const span = { 
        name, 
        startTime: performance.now(),
        attributes: attributes,
        events: []
      };
      return span;
    },
    
    endSpan: function(span) {
      span.endTime = performance.now();
      span.duration = span.endTime - span.startTime;
      
      // Enviar para backend de telemetria
      this.sendToCollector(span);
      return span.duration;
    },
    
    addEvent: function(span, name, attributes = {}) {
      if (span) {
        span.events.push({
          name,
          timestamp: performance.now(),
          attributes
        });
      }
    },
    
    sendToCollector: function(span) {
      // Enviar dados para o backend de telemetria
      const data = {
        name: span.name,
        duration: span.duration,
        attributes: span.attributes,
        events: span.events,
        timestamp: new Date().toISOString(),
        userAgent: navigator.userAgent,
        page: window.location.pathname
      };
      
      // Envia dados para um endpoint de telemetria
      try {
        navigator.sendBeacon('/telemetry', JSON.stringify(data));
      } catch (e) {
        // Fallback para fetch se sendBeacon não for suportado
        fetch('/telemetry', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(data),
          keepalive: true
        }).catch(err => console.error('Erro ao enviar telemetria:', err));
      }
    }
  };
  
  // Monitoramento automático de recursos
  const observer = new PerformanceObserver((list) => {
    list.getEntries().forEach((entry) => {
      // Enviar métricas apenas para recursos importantes
      if (entry.initiatorType === 'fetch' || entry.initiatorType === 'xmlhttprequest') {
        const telemetryData = {
          name: 'resource_timing',
          attributes: {
            resource: entry.name,
            initiatorType: entry.initiatorType,
            duration: entry.duration,
            startTime: entry.startTime,
            responseEnd: entry.responseEnd
          }
        };
        
        // Enviar dados para o coletor
        window.telemetry.sendToCollector(telemetryData);
      }
    });
  });
  
  // Observar eventos de recurso e navegação
  observer.observe({ entryTypes: ['resource', 'navigation'] });
  
  console.log('Telemetria inicializada no frontend');
})();
