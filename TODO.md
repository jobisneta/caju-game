# TODO - Caju Game

- [x] Pop-Up com tutorial para movimentação básica (WASD/setas) e ícone '?' para reabrir
- [x] Corrigir mecânica de subir escada (evitar que personagens se movam juntos)
- [x] Transição para nova fase quando ambos os personagens tocam a borda superior ao subir a escada
- [x] Alterar o fundo da janela de tutorial para a imagem "fundo_janela.png"
- [x] Alterar o fundo do botao da janela de tutorial para a imagem "fundo_botao.png"
- [x] Alterar o botao do tutorial para "botao_ajuda.png" que ja possui "?" desenhado.
- [x] Montar uma UI funcional que mostra o persongem e vida disposta de forma semelhante ao exemplo em "inspirations/personagem_UI". Nao ha nada que tire vida dos personagens no momento, mas deixar uma funçao pronta para isso.
- [x] Remover o Caju2 das primeiras fases "res://src/levels/home/". Deve ter apenas um personagem jogavel (Caju) nas fases "home".
- [x] Adicionar a personagem Kiki para as fases "res://src/levels/telhado/". Kiki pula mais baixo que Caju, mas pode planar. Ela usa as animaçoes idle, walk, jump e glide.
- [x] Adicionar o asset "res://assets/art/world/telhado/arvore_noite.png" na fase "res://src/levels/telhado/" no fundo da fase e alguns no plano a frente dos pesonagens. No estilo de "inspirations/arvores_telhado.jpg"
- [x] Criar uma HUD para coleta de itens logo abaixo da PlayerHUD. Por enquanto, ela deve mostrar um texto falando para coleta os itens, os itens que devem ser coletados na fase e o numero de itens, como em "inspirations itens_HUD.png".
- [x] O jogador nao deve poder passar de fase sem ter coletado todos os itens.
- [x] Criar um botao de interaçao para o Caju, tecla "E". Para o caju interagir com itens que pode derrubar.
- [x] Na fase "res://src/levels/home/home_1.tscn", caju deve ser capaz de interagir a direita da "CaixaPos1". Isso deve derrubar a caixa para esquerda visualmente, porem quero que ela caia exatamente no lugar de "CaixaPos2".
- [x] Verificar o implementaçao do personagem Tody na fase "res://src/levels/jardim/garden_1.tscn".
- [x] Adicionar uma caixa como "res://assets/art/world/home/crate.png" na fase "res://src/levels/jardim/garden_1.tscn".
- [x] Permitir que o Tody empurre a caixa ao se mover contra ela, apenas o Tody deve ser capaz de empurrar caixas.
