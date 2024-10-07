# AWS APP Runner with RDS powered by Terraform 

Este repositório contém um Terraform que fornece a infraestrutura de um AWS RDS, ECR e App Runner para rodar containers na AWS sem precisar gerenciar muita infraestrutura na AWS.

## Requisitos

- Terraform v1.9
- NodeJS v22.9
- Docker Compose v2
- Make

## Como utilizar

Siga o guia a seguir para realizar todas as configurações necessárias para conseguir deployar este projeto na AWS.

### Ferramentas para instalar 

1. Instale o [Terraform](https://developer.hashicorp.com/terraform/install?product_intent=terraform) na sua máquina de acordo com o seu sistema operacional.

## Criando nossa Infra com o Terraform

O Terraform é uma das ferramentas de mercado para criação de Infraestrutura em nuvem baseada em código. Para trabalharmos com ele em nossa máquina, precisamos executar alguns passos para conseguirmos criar nossa infraestrutura.

### Na AWS

Para rodarmos o Terraform precisamos de uma credencial de acesso à AWS.
Para isso entre em sua conta AWS e crie um usuário comum no IAM. 
1. Procure por IAM no console da AWS.
2. Vá ao menu Gerenciamento de Acesso -> Usuários.
3. Clique em criar usuário
4. Dê um nome ao seu usuário e clique em próximo. 
5. Na janela de Definir Permissões, selecione a opção de "Anexar Políticas Diretamente" e marque a opção "AdministratorAccess" na lista de políticas carregada. Clique em próximo. 
6. Clique em Criar o Usuário.

Agora precisamos criar as credenciais de acesso que o Terraform possa executar ações para nós na AWS.
Para isso clique no seu usuário.

1. Escolha a aba Credenciais de Segurança
2. Clique em Criar chave de acesso
3. Escolha a opção "Command Line Interface (CLI)"
4. Clique na caixinha de confirmação "Compreendo a recomendação acima e quero prosseguir para criar uma chave de acesso." e clique em próximo.
5. Clique em "Criar chave de acesso"
6. Faça o download do CSV com as credenciais ou salve os valores da "Chave de Acesso" e "Chave de acesso secreta" em um local seguro na sua máquina.
   
> 🚨 Lembre-se estamos criando uma credencial com poder administrativo na AWS. Essas credenciais são extremamente sensíveis e seu vazamento pode comprometer a sua conta. Quando não estiver utilizando, desative-a ou a destrua via console da AWS.

### Na sua máquina

Abra um terminal e exporte as variáveis da AWS na sua máquina para podermos criar a infraestrutura.
```shell
export AWS_ACCESS_KEY_ID=<preencha_aqui>
export AWS_SECRET_ACCESS_KEY=<preencha_aqui>
```

No seu editor de código favorito, abra este projeto.
Para executarmos o Terraform na AWS precisaremos fazer algumas configurações relativas ao seu projeto. E essas configurações estão no arquivo [`infra/locals.tf`](./infra/locals.tf).

Neste arquivo será necessário editar as variáveis:
- `name`: Troque para o nome do seu projeto. Não use espaços.
- `application.port`: Se sua aplicação está rodando em outra porta, confire a mesma aqui.
- `reponame`: Essa variável será o "Principal" na Role do IAM que vai permitir o GitHub Actions de deployar a imagem do ECR na AWS. Então precisamos definir certinho esse valor para não termos erros no deploy. O valor que está de exemplo deste repositório define que este repositório, quando estiver rodando pipelines a partir de tags pode fazer deploy na AWS. Se desejar outra configuração, confira o link disponibilizado no arquivo para entender como montar essa string.

Primeiramente vamos precisar criar toda a nossa infraestrutura exceto o App Runner, pois a detecção de dependências do Terraform não consegue realizar o `plan` do projeto sem que ao menos o ECR já esteja criado na nossa conta.
Por isso será necessário comentar todo o arquivo [`infra/runner.tf`](./infra/runner.tf).

Após realizar as alterações acima, execute os comandos a seguir:

```shell
cd infra
# Com esse comando baixamos as dependências do terraform que utilizaremos no nosso projeto, é como se fosse o npm install
terraform init
# Aqui faremos o planejamento da nossa infraestrutura. O terraform vai "calcular" o que precisa criar e executar na aws
terraform plan -out=plan
# Aqui aplicaremos o plano que o terraform criou na AWS
terraform apply plan
```
Após o fim do apply, o Terraform te passará um estado da sua infra com uma variável de output chamada `iam_role`. Salve o valor retornado pois usaremos ele no GitHub Actions.

Após a ação acima, descomente o arquivo `infra/runner.tf` e execute os comandos de `plan` e `apply` novamente.
> Ao executar o apply para criar o App Runner isso pode demorar alguns minutos já que todo o arcabouço de infra está sendo criado. Não suspenda a execução do Terraform. Deixa rodando e vai fazer outra coisa 😬

Após a aplicação do Plan sua infraestrutura já deve estar totalmente criada na AWS. Confira as mesmas no console do App Runner, ECR e RDS.

#### 🚨 Alguns recursos utilizados podem acarretar custos na AWS fora do Free Tier. Ao não utilizar mais este projeto, realize a destruição da infraestrutura.

Para destruir a sua infraestrutura após o fim dos seus estudos utilize o comando:
```shell
terraform plan -out=plan --destroy
terraform apply plan
```
> Na criação de uma infraestrutura com o Terraform, é salvo localmente um arquivo com a extensão `tfstate`. Esse arquivo contém o estado da nossa infraestrutura e é um dê-para do que tem no terraform local e o que foi criado na AWS. Esse arquivo não pode ser perdido, e existem algumas formas de salvarmos ele em outros lugares, mas nesta demo, estamos mantendo esse arquivo localmente. Muito cuidado para não perder esse arquivo, pois sem ele o Terraform poderá recriar os recursos já criados ou não saber o que deletar no momento do destroy. Esse arquivo também **não** deve ser comittado no repositório por conter dados sensíveis de sua infraestrutura.

### Dicas para cuidar da sua infra

- A infra do App Runner pode ser destruída e criada facilmente, caso não esteja utilizando, basta definir a variável `create_service` para `false` e rodar os comandos de `plan` e `apply`.
- Desative seu RDS enquanto não estiver utilizando a partir do console, para evitar cobranças indevidas em caso de estourar o free tier.

### GitHub Actions

O pipeline disponibilizado é executado a partir de push pra branch `main` do seu repositório. Todo push irá realizar um novo deploy de imagem no ECR.
O mesmo realiza o build o projeto e publica a imagem no ECR na AWS. A estrutura criada sempre deploya a aplicação com a mesma tag `latest`.

Para que o pipeline execute, é necessário criar uma variável do tipo `Secret` nas configurações de ambiente do seu GitHub.
1. Abra seu repositório no GitHub
2. Vá ao menu Settings (ou Configurações)
3. Na opção Secrets and Variables clique em Actions
4. Adicione um novo secret do repositório.
   1. Esse segredo deve ter o nome `AWS_ASSUME_ROLE` e conter o ARN do IAM Role que criamos no passo do Terraform.

## Demo API

Este projeto possui uma API feita com o NestJS, com um "Hello World" na rota raiz para demonstração da infraestrutura como App Runner.
A aplicação também conta com a integração com o [TypeORM](https://typeorm.io) a partir da integração nativa do [NestJS](https://docs.nestjs.com/techniques/database#typeorm-integration). 

Também possuímos uma rota chamada `/health` que o AppRunner utiliza para validar a integridade do container. A mesma retorna um Json dizendo se a conexão com o banco de dados está ok. 
Caso essa rota retorne qualquer status code diferente de 200, o AppRunner vai considerar o container **unhealthy** e derrubar o mesmo (ou nem subir a nova versão caso o health check não passe).

Você pode utilizar esta aplicação como base do seu projeto, ou utilizar outro projeto Node (ou em sua linguagem favorita). Note que deverá alterar o `compose.yml` para apontar para o Dockerfile de build do seu projeto.

Através do `compose.yml` podemos rodar nossa Demo API localmente. Para executá-la basta utilizar o comando `make up`.

## Configurações do RDS

Note no arquivo `infra/runner.tf` que configuramos entre as linhas 42 e 51 as variáveis de ambientes do container da Demo Api. A sua aplicação deve ler do ambiente esses valores a partir das configurações da env definidas nesse arquivo. Caso contrário, sua aplicação não conseguirá se conectar com o banco.

> Se estiver utilizando outro framework que não seja o NestJS, se utilize da estrutura definida em [`demo-api/src/app.module.ts`](demo-api/src/app.module.ts) para configurar seu TypeORM.

> Também note que estamos utilizando na aplicação o usuário master do banco. Como isso é apenas uma demo para testes, não há muito problema. Mas nunca utilize em um ambiente produto o usuário master do banco em sua aplicação.

### Migrações

Este projeto não consta com a configuração de rodar as migrações. Você precisa configurar sua aplicação para rodar as migrações automaticamente ao iniciar o container. Você pode fazer isso utilizando comandos do TypeORM em um script de start da aplicação.