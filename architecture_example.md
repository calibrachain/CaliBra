### **Arquitetura Detalhada do MVP: Marketplace de Rastreabilidade Metrológica**
![Diagrama da Arquitetura do MVP](images/diagram.png)

#### **1. Visão Geral**

Esta documentação descreve a arquitetura técnica para o MVP do Marketplace de Rastreabilidade Metrológica. O objetivo é criar um fluxo seguro, eficiente e escalável para a emissão de Certificados de Calibração Digitais (DCCs) como NFTs, utilizando Chainlink Functions para verificação de dados do mundo real.

A arquitetura se baseia em um **único e central smart contract** que atua como uma "fábrica" de NFTs, orquestrando a validação e a criação de todos os certificados.

#### **2. Diagrama da Arquitetura**

O fluxograma a seguir ilustra a interação entre os componentes, desde a ação do usuário no frontend até a criação do NFT na carteira do cliente.

```mermaid
sequenceDiagram
    participant FE as Frontend (Interface do Laboratório)
    participant IPFS as IPFS (Armazenamento Descentralizado)
    participant DCC as DCCRegistry (Smart Contract ERC-721)
    participant CLF as Chainlink Functions
    participant NMI as API Externa (Ex: INMETRO)
    participant Cliente as Carteira do Cliente

    Note over FE, Cliente: Fase 1: Preparação e Armazenamento

    FE->>IPFS: 1. Upload do arquivo do certificado (PDF/XML)
    IPFS-->>FE: Retorna o Hash do Arquivo (fileHash)

    FE->>FE: 2. Cria o arquivo JSON de metadados
    Note right of FE: Inclui nome, data, atributos, fileHash e dados de rastreabilidade

    FE->>IPFS: 3. Upload do arquivo de metadados (JSON)
    IPFS-->>FE: Retorna o Hash do Metadado (tokenURI)

    Note over FE, Cliente: Fase 2: Verificação e Criação do NFT

    FE->>DCC: 4. Chama `solicitarEmissaoCertificado(...)`

    DCC->>CLF: 5. Invoca Chainlink Function para verificar laboratório
    CLF->>NMI: 6. Consulta API externa com `labIdentifier`
    NMI-->>CLF: Retorna status (ex: { "accredited": true })
    CLF-->>DCC: 7. Chama `fulfillRequest` com a resposta

    DCC->>DCC: 8. Se verificado (true), executa a lógica de mint
    DCC->>Cliente: 9. `_safeMint()` cria o NFT diretamente na carteira do Cliente

    Cliente-->>DCC: Confirmação da posse do novo NFT
```

#### **3. Fluxo Detalhado Passo a Passo**

1.  **Preparação e Upload (Frontend):**
    * O usuário (laboratório) acessa a interface web.
    * Ele preenche os dados do certificado e faz o upload do arquivo principal (ex: `certificado.pdf`).
    * O frontend envia este arquivo para o **IPFS**, que retorna um hash único (`fileHash`).

2.  **Criação dos Metadados (Frontend e IPFS):**
    * Com o `fileHash` em mãos, o frontend monta dinamicamente um arquivo `metadata.json`. Este JSON segue o padrão da OpenSea/ERC-721 e contém todas as informações do certificado, incluindo um ponteiro para o arquivo original no IPFS e os **dados de rastreabilidade dos padrões utilizados na calibração**.
    * O frontend então faz o upload deste arquivo `metadata.json` para o **IPFS**, recebendo um segundo hash. Este hash é o **`tokenURI`** final do NFT.

3.  **Chamada ao Smart Contract (Frontend -> Blockchain):**
    * O usuário clica em "Emitir Certificado".
    * O frontend inicia uma transação na blockchain, chamando a função `solicitarEmissaoCertificado` do nosso contrato.
    * Os parâmetros enviados são:
        * `clienteAddress`: O endereço da carteira do cliente que receberá o NFT.
        * `tokenURI`: O hash do IPFS para o arquivo `metadata.json`.
        * `labIdentifier`: O identificador único do laboratório (CNPJ, nome, etc.) que será usado para a consulta na API externa.

4.  **Orquestração e Verificação (Smart Contract e Chainlink Functions):**
    * O contrato `DCCRegistry` recebe a chamada em `solicitarEmissaoCertificado`.
    * Ele **NÃO** cria o NFT imediatamente. Ele armazena os dados da solicitação e invoca a **Chainlink Function**, passando o `labIdentifier` como argumento.

5.  **Decisão e Criação do NFT (Smart Contract via Callback):**
    * A Chainlink executa o código off-chain e chama a função de callback `fulfillRequest` no contrato com a resposta.
    * O contrato possui uma lógica condicional dentro de `fulfillRequest`:
        * **Se a resposta for `true`:** A verificação foi um sucesso. O contrato recupera os dados da solicitação, procede e chama a função interna `_safeMint(clienteAddress, tokenId)` e `_setTokenURI`. O NFT é atribuído diretamente à carteira do cliente.
        * **Se a resposta for `false`:** A verificação falhou. A lógica de `mint` não é executada.

#### **4. Estrutura dos Metadados do NFT (Exemplo de `tokenURI`)**

O arquivo JSON de metadados é o coração do DCC NFT. Ele não só descreve o certificado, mas também estabelece a cadeia de rastreabilidade on-chain, agora alinhado com a terminologia padrão da indústria.

```markdown
```json
{
  "name": "Certificado de Calibração #12345",
  "description": "Certificado para o medidor de pressão modelo P-500 da Indústria XYZ.",
  "image": "ipfs://QmXyZ...[hash_de_uma_imagem_preview_do_certificado_ou_equipamento].jpg",
  "certificate_file": "ipfs://QmABC...[hash_do_arquivo_PDF_ou_XML_do_certificado].pdf",
  "attributes": [
    {
      "trait_type": "Laboratório Emissor",
      "value": "LabCalibrações Confiança Ltda."
    },
    {
      "trait_type": "Data de Emissão",
      "value": "2025-06-15"
    },
    {
      "trait_type": "Data de Expiração",
      "value": "2026-06-14"
    },
    {
      "trait_type": "Instrumento Calibrado",
      "value": "Medidor de Pressão P-500 / SN: 987654"
    },
    {
      "trait_type": "Serial Number",
      "value": "987654"
    }
  ],
  "measuring_equipments": [
    {
      "name": "Certificado de Calibração #5678",
      "identifications": [
        { "type": "serialNumber", "value": "123-ABC" }
      ],
      "onchain_address": "eip155:43114/erc721:0x1234...abcd/789"
    }
  ]
}
```
```

**Análise dos Campos de Rastreabilidade:**

* **`measuring_equipments`**: **(NOME ALINHADO AO PADRÃO)** Um array de objetos que lista os equipamentos padrão utilizados para a calibração. O nome está agora alinhado com o padrão oficial DCC, o que aumenta a clareza e a interoperabilidade do projeto.
* **`name`**: O nome ou identificador do certificado de calibração do equipamento padrão (ex: "Certificado de Calibração #5678").
* **`identifications`**: Um array para os identificadores do equipamento padrão, como o número de série.
* **`onchain_address`**: O elo on-chain que aponta para o NFT do certificado de referência. Renomeado para maior clareza. O formato `eip155:[chainId]/erc721:[contractAddress]/[tokenId]` é mantido por ser ideal para um futuro cross-chain.

#### **5. Perguntas e Respostas (FAQ da Arquitetura)**

**P1: Eu crio apenas um contrato e minto por ele?**
**R:** Sim, exatamente. A arquitetura correta e escalável utiliza um único contrato padrão ERC-721 que funciona como um "Registro" ou "Fábrica" central. Cada novo certificado validado é simplesmente um novo token (NFT) criado por este mesmo contrato, com seu próprio `tokenId` e `tokenURI` exclusivos.

**P2: Como funciona o upload do JSON de metadados e do IPFS?**
**R:** É um processo crucial de duas etapas para garantir a descentralização e a integridade:

1.  **Armazenar o Ativo Principal:** Primeiro, o arquivo bruto (PDF/XML do certificado) é enviado ao IPFS para obter seu hash de conteúdo (`fileHash`).
2.  **Armazenar os Metadados:** Em seguida, um arquivo JSON é criado. Este JSON contém os dados do NFT (nome, descrição, atributos) e, mais importante, um campo que aponta para o ativo principal (`"certificate_file": "ipfs://<fileHash>"`) e os dados de rastreabilidade. Este arquivo JSON é então enviado ao IPFS para obter o `tokenURI` final.

**P3: O NFT é "mintado" diretamente para a carteira do dono?**
**R:** Sim. A função de `mint` (executada dentro do callback `fulfillRequest`) no seu smart contract receberá o endereço da carteira do cliente como um parâmetro. Ao criar o NFT, ele é imediatamente atribuído e transferido para a posse desse endereço.

**P4: O contrato é "ilimitado"?**
**R:** Sim, para todos os efeitos práticos. O `tokenId` em um contrato ERC-721 é um `uint256`, um número que pode chegar a 2^256 - 1. Este é um número astronomicamente grande.

#### **6. Resumo das Responsabilidades**

* **Frontend:**
    * Coletar dados do usuário.
    * Interagir com o IPFS para armazenar arquivos e metadados.
    * Construir e assinar transações para chamar o smart contract.
    * Exibir os resultados (sucesso ou falha) para o usuário.
* **IPFS:**
    * Prover armazenamento descentralizado e endereçável por conteúdo para os certificados e seus metadados.
* **Smart Contract (`DCCRegistry`):**
    * Atuar como o ponto central de confiança e lógica de negócios on-chain.
    * Gerenciar o controle de acesso (quem pode emitir certificados).
    * Orquestrar a verificação chamando a Chainlink Function.
    * Executar a lógica de `mint` condicional dentro do callback.
    * Manter o registro de posse de todos os DCCs.
* **Chainlink Functions:**
    * Atuar como a ponte segura entre a blockchain e a API do mundo real (NMI).
    * Executar a lógica de requisição e processamento de dados off-chain.
    * Retornar um resultado confiável e conciso para o smart contract via callback.

---

#### **7. Exemplo de Smart Contract (`DCCRegistry.sol`) com Fluxo da Chainlink**

Abaixo está o exemplo de contrato modificado para incluir o padrão completo de **Requisição e Retorno** da Chainlink Functions.

##### **Código JavaScript para a Chainlink Function (`source.js`)**
```javascript
// Exemplo de código que roda na Chainlink Function
// Ele recebe o CNPJ do laboratório como argumento.

const labCnpj = args[0];

// Para o hackathon, podemos usar uma lógica mock:
const accreditedLabs = {
  "00.111.222/0001-33": true,
  "99.888.777/0001-55": false,
};

const isAccredited = accreditedLabs[labCnpj] || false;

// Retornamos o booleano codificado para o contrato.
return Functions.encodeBool(isAccredited);
```

##### **Contrato Solidity (`DCCRegistry.sol`)**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Importações necessárias para Chainlink Functions
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/libraries/FunctionsRequest.sol";

contract DCCRegistry is ERC721, FunctionsClient, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // --- State da Chainlink Functions ---
    bytes32 public donId; // ID da rede de oráculos (DON) a ser usada
    uint64 public subscriptionId; // ID da sua assinatura de faturamento na Chainlink
    string public source; // O código-fonte Javascript da sua função

    // --- Lógica de Requisição e Retorno ---

    // Struct para armazenar os detalhes de uma solicitação enquanto esperamos a resposta
    struct Request {
        address cliente; // Para quem o NFT será mintado
        string tokenURI; // O URI do metadado do NFT
        bool sent; // Flag para saber se a requisição foi enviada
    }

    // Mapeamento de requestId para os detalhes da solicitação
    mapping(bytes32 => Request) public activeRequests;

    event RequestSent(bytes32 indexed requestId);
    event RequestFulfilled(bytes32 indexed requestId, bool response);
    event CertificateMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);

    constructor(address oracleAddress, bytes32 _donId, uint64 _subscriptionId, string memory _source) 
        ERC721("Digital Calibration Certificate", "DCC") 
        FunctionsClient(oracleAddress)
    {
        donId = _donId;
        subscriptionId = _subscriptionId;
        source = _source;
    }

    /**
     * @notice PASSO 1: Solicita a emissão de um certificado.
     * @dev Envia a requisição para a Chainlink e armazena os dados para o callback.
     * @param cliente Endereço que receberá o NFT.
     * @param tokenURI Link IPFS para os metadados.
     * @param labIdentifier Identificador do laboratório a ser verificado (ex: CNPJ).
     */
    function solicitarEmissaoCertificado(address cliente, string memory tokenURI, string memory labIdentifier)
        public
        onlyOwner
        returns (bytes32 requestId)
    {
        string[] memory args = new string[](1);
        args[0] = labIdentifier;

        FunctionsRequest.Request memory req;
        req.initializeRequest(FunctionsRequest.Location.Inline, FunctionsRequest.CodeLanguage.JavaScript, source, args, new bytes(0), 60000); // 60s timeout

        requestId = _sendRequest(req.encodeCBOR(), subscriptionId, 300000, donId);

        // Armazena os detalhes da solicitação, usando o requestId como chave
        activeRequests[requestId] = Request({
            cliente: cliente,
            tokenURI: tokenURI,
            sent: true
        });

        emit RequestSent(requestId);
        return requestId;
    }

    /**
     * @notice PASSO 2: Função de callback que a Chainlink chama com a resposta.
     * @dev Recebe a resposta da API e, se for válida, executa a lógica final (mint).
     * @param requestId O ID da requisição original.
     * @param response A resposta da sua função Javascript (o booleano codificado).
     * @param err Qualquer erro que tenha ocorrido.
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err)
        internal
        override
    {
        // Pega os dados da solicitação que foram salvos anteriormente
        Request storage request = activeRequests[requestId];
        require(request.sent, "Request not found or already fulfilled");

        emit RequestFulfilled(requestId, abi.decode(response, (bool)));

        // Se a resposta for um booleano `true`
        if (err.length == 0 && abi.decode(response, (bool))) {
            _tokenIds.increment();
            uint256 novoTokenId = _tokenIds.current();

            // Executa o mint e a associação do URI
            _safeMint(request.cliente, novoTokenId);
            _setTokenURI(novoTokenId, request.tokenURI);

            emit CertificateMinted(novoTokenId, request.cliente, request.tokenURI);
        }

        // Limpa a solicitação para liberar espaço e evitar re-uso
        delete activeRequests[requestId];
    }
}
`
