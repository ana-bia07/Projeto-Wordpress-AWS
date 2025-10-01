# Projeto WordPress em AWS com Docker e Docker Compose
![AWS](https://img.shields.io/badge/AWS-%23FF9900?style=for-the-badge&logo=icloud&logoColor=white)
![DOCKER](https://img.shields.io/badge/docker-blue?style=for-the-badge&logo=Docker&logoColor=white)

Este projeto tem como objetivo criar uma aplicação Wordpress rodando atravez de um docker composse em alta escalibilidade e resiliencia na AWS, utilizando boas praticas de DevOps.  
A arquitetura foi projetada para separar as camadas de **rede**, **aplicação** e **dados**, garantindo alta disponibilidade e gerenciamento facilitado.

![Estrutura](imagens/estrutura.png)

---

## 🚀 Tecnologias e Serviços Utilizados

- **Infraestrutura como Código (IaC)**: Script Bash para automação.
- **Contêineres**: Docker e Docker Compose.
- **AWS**:
  - **EC2**: Instâncias para o WordPress e Bastion Host.
  - **VPC**: Rede virtual isolada.
  - **RDS**: Banco de dados MySQL gerenciado para o WordPress.
  - **EFS**: Sistema de arquivos elástico para o diretório de uploads do WordPress.
  - **ALB**: Application Load Balancer para distribuir o tráfego.
  - **Auto Scaling**: Grupo para gerenciar a escalabilidade das instâncias.
  - **Internet Gateway & NAT Gateway**: Conectividade com a internet.
  - **Security Groups**: Controle de acesso de rede.

---

## 🏗️ Arquitetura da Solução

A arquitetura se baseia em uma **VPC** com duas zonas de disponibilidade (1a e 1b), garantindo alta disponibilidade.

### Subnets
- **2 Subnets Públicas**: Para o Bastion Host e os NAT Gateways.
- **2 Subnets Privadas de Aplicação**: Para as instâncias EC2 do WordPress, gerenciadas pelo Auto Scaling.
- **2 Subnets Privadas de Dados**: Para o banco de dados RDS e o EFS.

### Gateways
- **Internet Gateway**: Anexado à VPC, permite comunicação com a internet.
- **NAT Gateways**: Dois NAT Gateways com IPs estáticos, localizados nas subnets públicas, para permitir que as instâncias nas subnets privadas acessem a internet.

---

## 💰 Atenção aos Custos
A arquitetura descrita (**IPs estáticos** , **NAT Gateways** , **RDS** , **EFS** , **AutoScaling** , **LoadBalance**) gera custos na AWS.  
Planeje seu uso para evitar cobranças indesejadas.

---

## 📋 Guia de Instalação e Configuração

### 1. Configuração da VPC e da Rede
1. Crie uma VPC chamada **vpc-wordpress** com o IP `10.0.0.0/16` e habilite DNS.
2. Crie um **Internet Gateway** e anexe à VPC.

![Estrutura](imagens/attach-gtw.png)

3. Crie **6 subnets**:
   - 2 pública para cada zona de disponibilidade (1a e 1b).
   - 2 privadas (app) para cada zona de disponibilidade (1a e 1b).
   - 2 privadas (data) para cada zona de disponibilidade (1a e 1b).
  
![Estrutura](imagens/subnets.png)

4. Crie **2 IPs estáticos**

![Estrutura](imagens/ip-static.png)

5. **2 NAT Gateways** nas subnets públicas.
Crie as nat gateways com os ip criados anteriormente.

![Estrutura](imagens/natgateway.jpg)
    
6. Configure as **tabelas de rotas**:
   - Subnets públicas → `0.0.0.0/0` para o Internet Gateway.

![Estrutura](imagens/route-tables-rotas.png)

   - Subnets privadas (app e data) → `0.0.0.0/0` para os NAT Gateways.
     
![Estrutura](imagens/route-tables-rotas-privadas.png)

deve ficar assim:

![Estrutura](imagens/route-tables-subnats.png)

Você pode conferir a estrutura em VPC > Suas VPC > mapa de rede:

![Estrutura](imagens/mapa-de-rede.png)

---

### 2. Criação dos Security Groups
#### **Bastion Host** :
**Regra de entrada:**
| Tipo | Porta | Destino |
|------|-------|---------|
| SSH  |  22   | My Ip   | 
| HTTP |  80   | Sg-ALB  |

**Regra de saida:**
| Tipo | Porta | Destino|
|-------------|---|---------|
| All traffic | - | 0.0.0.0 |

![Estrutura](imagens/sg-regra-bastion.png)

#### **Instância WordPress**:
**Regra de entrada:**
| Tipo | Porta | Destino |
|------|-------|---------|
| SSH  |  22   | Sg-Bastion | 
| HTTP |  80   | Sg-ALB  |

**Regra de saida:**
| Tipo | Porta | Destino|
|------|-------|--------|
| All traffic | - | 0.0.0.0 |
| MYSQL/Aurora | 3306 | Sg-RDS |

![Estrutura](imagens/sg-regra-ec2.png)

#### **LoadBalancer**:
**Regra de entrada:**
| Tipo | Porta | Destino|
|------|-------|--------|
| HTTP |   80  | 0.0.0.0 |

**Regra de saida:**
| Tipo | Porta | Destino|
|------|-------|--------|
| HTTP |   80  | Sg-EC2 |

![Estrutura](imagens/sg-regra-ALB.png)

#### **RDS**:
**Regra de entrada:**
| Tipo | Porta | Destino |
|------|-------|---------|
| MYSQL/Aurora | 3306 | Sg-EC2 |

**Regra de saida:**
| Tipo | Porta | Destino |
|------|-------|---------|
| All traffic | - | 0.0.0.0 |

![Estrutura](imagens/sg-regra-rds.png)
  
#### **EFS**:
**Regra de entrada:**
| Tipo | Porta | Destino |
|------|-------|---------|
| NFS | 2049 | Sg-EC2 |

**Regra de saida:**
| Tipo | Porta | Destino |
|------|-------|---------|
| All traffic | - | 0.0.0.0 |

![Estrutura](imagens/sg-regra-efs.png)

---
### 3. Criação do Grupo de subnets
Em Aurora e RDS, va para grupo de subnets e clique em criar.
1. Ecolha a VPC
2. Anexe as subnets private-data:

![Estrutura](imagens/group-subnet.png)

---

### 4. Criação do Banco de Dados RDS
1. Crie uma instância **MySQL**.
2. Modelo nivel gratuito. 
3. Nomeie como `wordpress-db`, usuário `admin`, senha `02teste07`.
4. Intancia tipo db.t3.micro
5. Conecte à VPC criada e desabilite acesso público.
6. Escolha o gruo de subnets criado anteriomente.
7. Escolha o segurity group criado anteriormente.
8. Zona de preferencia A.
9. Abilite logs de erro e crie o banco.

![Estrutura](imagens/rds.png)

---

### 4. Criação do EFS
Em EFS clique em cria sistema de arquivos:
1. Crie um sistema de arquivos **EFS** chamado `efs-wordpress`.
2. Clique em personalizar.
3. Escolha regional.
4. Escolha a VPC e as AZ 1a e 1b, às subnets privadas-app e associe o SG do EFS.
5. E Crie.

![Estrutura](imagens/efs-verde.png)

---

### 5. Configuração do Bastion Host
1. Crie uma instância EC2 (Amazon Linux) em uma subnet pública.
2. Crie uma chave se não tiver ainda.
3. Habilite IP público.
4. Associe o **SG do Bastion Host**.
5. No seu terminal, dentro da pasta donwload que contem sua chave, execute:
```bash
scp -i "sua-chave.pem" sua-chave.pem ec2-user@<IP_PÚBLICO_DO_BASTION_HOST>:~/.ssh
chmod 400 "sua-chave.pem"
```
acesse a instancia Bastion com o comando:
```bash
ssh -i "sua-chave.pem" ec2-user@<IP-PUBLICO-BASTION>
```
e execute:
```bash
chmod 400 /.ssh/"sua-chave.pem" #para dar permisão a sua chave dentro da isntancia bastion
```bash
caso queira acessar sua instancia privada:
```
ssh -i "sua-chave.pem" ec2-user@<IP-PRIVADO-INSTANCIA>
```bash

Essa intancia (bastion) tem a função principal deo ponte para que possamos acessar as instancia privadas. Nesse documento não usamos eles mas caso tenha algum problema recomendo verificar a instancia privada atraves desses comandos.
Aqui alguns comando que podem te ajudar:
```bash
docker --version #verificar a instalação do docker
docker logs wordpress-container #ver os logs do container e verificar status do container
cat /var/log/wordpress.log #log da instancia
df -h #uma forma de verificar se o efs esta montado
```

---

### 6. Criação do Launch Template
Crie um **Launch Template** para as instâncias WordPress.
- Intancia Amazo/Linux
- Tipo: `t2.micro`
- Key Pair: sua chave SSH
- VPC criada
- SG: SG da instância
- Não coloque subnet
Adicione o seguinte User-Data: [📄 Clique aqui para ver o script no repositório](https://github.com/ana-bia07/Projeto-Wordpress-AWS/blob/master/User-Data.sh)

### 7. Criando Target
- Tipo para Instancia
- de um nome
- Escolha a VPC criada
- E nas configurações avançadas de saude adicione: 200,302

![Estrutura](imagens/target-group.png)

---

### 8. Criando Load Balancer
- Escolha para aplicação
- De um nome
- tipo internet-facing
- Escolha a VPC
- Adicione as subnets private-app 1a e 1b
- E o segurity group do ALB
- Escolhe o target group que criamos
- Mantenha o resto e crie.

---

### 9. Criando AutoScaling
- Nomeie o autoscaling e escolha o template que criamos

![Estrutura](imagens/autoscaling1.png)

- Escolha a VPC e as subnets private-app

![Estrutura](imagens/autoscaling2.png)

-Em Load Balancer escolha adicionar existe e coloque o target group criado

![Estrutura](imagens/autoscaling3.png)

- Por fim coloque a capacidade desejada

![Estrutura](imagens/autoscaling4.png)

![Estrutura](imagens/autoscaling5.png)

### Parabéns
Agora você pode consultar suas instancia criada em Instancias.
Sua aplicação é auto-escalavel e pode suportar muitos acessos de forma segura para todos.
Você pode verificar a saude dos no target group, deve ter 2 Health.



