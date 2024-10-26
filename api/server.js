const express = require('express');
const cors = require('cors'); // Importando o CORS
const axios = require('axios'); // Para fazer requisições HTTP
const cheerio = require('cheerio'); // Para manipulação do HTML

const app = express();
const port = 9090;

const monitoresData = require('./monitores.json');

// Habilitar CORS para todas as origens
app.use(cors());

app.get('/', (req, res) => {
  res.send("Olá");
});

app.get('/monitores', (req, res) => {
  res.json(monitoresData);
});

app.get('/cardapio', async (req, res) => {
  try {
    const cardapios = {};
    const hoje = new Date();
    
    let diaAtual = hoje.getDay();
    let dataInicio = new Date(hoje);
    let dataFinal = new Date(hoje);

    // Se for sábado, vai até o próximo domingo (da próxima semana)
    if (diaAtual === 6) {
      dataFinal.setDate(hoje.getDate() + 8); // Próximo domingo (8 dias a partir de hoje)
    } else {
      // Se não for sábado, define apenas o próximo domingo
      const diasParaDomingo = 8 - (diaAtual + 1);
      dataFinal.setDate(hoje.getDate() + diasParaDomingo);
    }

    // Loop para pegar os dias entre dataInicio e dataFinal
    while (dataInicio <= dataFinal) {
      const dataFormatada = dataInicio.toISOString().split('T')[0];

      const response = await axios.get(`https://sistemas.prefeitura.unicamp.br/apps/cardapio/index.php?d=${dataFormatada}`, {
        responseType: 'arraybuffer',
        responseEncoding: 'binary'
      });

      const html = Buffer.from(response.data, 'binary').toString('latin1');
      const $ = cheerio.load(html);

      cardapios[dataFormatada] = {
        Almoço: {
          principal: '',
          acompanhamento: [],
          observacao: ''
        },
        Jantar: {
          principal: '',
          acompanhamento: [],
          observacao: ''
        }
      };

      $('.menu-section').each((index, element) => {
        const title = $(element).find('.menu-section-title').text().trim() || '';
        const dishName = $(element).find('.menu-item-name').text().trim() || '';
        const dishDescription = $(element).find('.menu-item-description').html();

        if (title === "Almoço") {
          cardapios[dataFormatada].Almoço.principal = dishName;

          // Extraindo acompanhamentos e observações
          if (dishDescription) {
            const acompanhamentoParts = dishDescription.split('<br>').map(item => item.trim()).filter(item => item.length > 0);
            const observacaoIndex = acompanhamentoParts.indexOf('Observações:');

            // Remove a linha que menciona "cardápio vegano"
            acompanhamentoParts.forEach((part, index) => {
              if (part.toLowerCase().includes('cardápio vegano')) {
                acompanhamentoParts.splice(index, 1);
              }
            });

            if (observacaoIndex !== -1) {
              cardapios[dataFormatada].Almoço.acompanhamento = acompanhamentoParts.slice(0, observacaoIndex).filter(item => item.length > 0);
              // Limpa tags HTML e substitui <br> por \n
              cardapios[dataFormatada].Almoço.observacao = acompanhamentoParts.slice(observacaoIndex + 1).join('\n').replace(/<[^>]+>/g, '').trim();
            } else {
              cardapios[dataFormatada].Almoço.acompanhamento = acompanhamentoParts;
              cardapios[dataFormatada].Almoço.observacao = '';
            }
          }
        } else if (title === "Jantar") {
          cardapios[dataFormatada].Jantar.principal = dishName;

          // Extraindo acompanhamentos e observações
          if (dishDescription) {
            const acompanhamentoParts = dishDescription.split('<br>').map(item => item.trim()).filter(item => item.length > 0);
            const observacaoIndex = acompanhamentoParts.indexOf('Observações:');

            // Remove a linha que menciona "cardápio vegano"
            acompanhamentoParts.forEach((part, index) => {
              if (part.toLowerCase().includes('cardápio vegano')) {
                acompanhamentoParts.splice(index, 1);
              }
            });

            if (observacaoIndex !== -1) {
              cardapios[dataFormatada].Jantar.acompanhamento = acompanhamentoParts.slice(0, observacaoIndex).filter(item => item.length > 0);
              // Limpa tags HTML e substitui <br> por \n
              cardapios[dataFormatada].Jantar.observacao = acompanhamentoParts.slice(observacaoIndex + 1).join('\n').replace(/<[^>]+>/g, '').trim();
            } else {
              cardapios[dataFormatada].Jantar.acompanhamento = acompanhamentoParts;
              cardapios[dataFormatada].Jantar.observacao = '';
            }
          }
        }
      });

      // Avança para o próximo dia
      dataInicio.setDate(dataInicio.getDate() + 1);
    }

    res.json(cardapios);
  } catch (error) {
    console.error("Erro ao buscar cardápios:", error);
    res.status(500).json({ error: "Erro ao buscar cardápios" });
  }
});






app.listen(port, () => {
  console.log(`Servidor rodando em http://localhost:${port}`);
});

module.exports = app;