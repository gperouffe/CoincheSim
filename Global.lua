AtoutOrderMap = BuildIndexOfMap({
    "Jack", "9", "1", "10", "King", "Queen", "8", "7"
})
NonAtoutOrderMap = BuildIndexOfMap({
    "1", "10", "King", "Queen", "Jack", "9", "8", "7"
})

function BuildIndexOfMap(array)
    local indexOfMap = {}
    for k, v in pairs(array) do indexOfMap[v] = k end
    return indexOfMap
end

function CompareCards(firstCard, secondCard, expectedColor, atoutColor)
    if firstCard.color == secondCard.color then
        local function sameColorCompare(orderMap)
            if orderMap[firstCard.figure] < orderMap[secondCard.figure] then
                return 1
            else
                return -1
            end
        end
        if firstCard.color == atoutColor then
            return sameColorCompare(AtoutOrderMap)
        else
            return sameColorCompare(NonAtoutOrderMap)
        end
    else
        if firstCard.color == atoutColor then
            return 1
        elseif secondCard.color == atoutColor then
            return -1
        elseif firstCard.color == expectedColor then
            return 1
        elseif secondCard.color == expectedColor then
            return -1
        else
            return 0
        end
    end
end

function GetCardValue(card, atoutColor)
    if card.color == atoutColor and card.figure == "Jack" then
        return 20
    elseif card.color == atoutColor and card.figure == "9" then
        return 14
    elseif card.figure == "1" then
        return 11
    elseif card.figure == "10" then
        return 10
    elseif card.figure == "King" then
        return 4
    elseif card.figure == "Queen" then
        return 3
    elseif card.figure == "Jack" then
        return 2
    else
        return 0
    end
end

function ComputeScore(cards, atoutColor)
    local score = 0
    for _, card in pairs(cards) do
        score = score + GetCardValue(card, atoutColor)
    end
    return score
end

function CreateCoinchePlayer(color)
    return {player = Player[color], color = color, hand = {}, team = nil}
end

function CreateTeam(coninchePlayer1, coinchePlayer2)
    local team = {
        players = {coninchePlayer1, coinchePlayer2},
        gameScore = 0,
        roundScore = 0
    }

    coninchePlayer1.team = team
    coinchePlayer2.team = team
    return team
end

local masterDeck = getObjectFromGUID("deckGuid")
masterDeck.hide()
local gameDeck = masterDeck.clone();

PlayerN = CreateCoinchePlayer("Green")
PlayerE = CreateCoinchePlayer("Red")
PlayerS = CreateCoinchePlayer("Blue")
PlayerW = CreateCoinchePlayer("Yellow")

TeamNS = CreateTeam(PlayerN, PlayerS)
TeamEW = CreateTeam(PlayerE, PlayerW)
Teams = {TeamNS, TeamEW}

PlayersInOrder = {PlayerN, PlayerE, PlayerS, PlayerW}

function GetNextPlayerIndex(currentPlayerIndex)
    return (currentPlayerIndex % 4) + 1
end

function GameLoop()
    gameDeck.shuffle()
    TeamNS.gameScore = 0
    TeamEW.gameScore = 0

    local firstPlayerIndex = 1
    while TeamNS.gameScore < 1000 and TeamEW.gameScore < 1000 do
        local roundInfo = AnnonceLoop(firstPlayerIndex)
        if roundInfo ~= nil then RoundLoop(roundInfo, firstPlayerIndex) end
        firstPlayerIndex = GetNextPlayerIndex(firstPlayerIndex)
    end

    local winner = (TeamNS.gameScore >= 1000) and TeamNS or TeamEW;
end

function AnnonceLoop(firstPlayerIndex)
    local currentStake = nil
    local passCount = 0
    local runningTeam = nil
    local isCoinche = false;
    local currentPlayerIndex = firstPlayerIndex

    while passCount < 3 or (passCount == 3 and runningTeam == nil) do
        local currentPlayer = PlayersInOrder[currentPlayerIndex]
        local playerStake = GetPlayerStake(currentPlayer)
        if playerStake == "coinche" then
            isCoinche = true
            break
        elseif playerStake == nil then
            passCount = passCount + 1
        else
            passCount = 0
            currentStake = playerStake
            runningTeam = currentPlayer.team
        end

        currentPlayerIndex = GetNextPlayerIndex(currentPlayerIndex)
    end

    if currentStake == nil then
        return nil
    else
        return {
            team = runningTeam,
            otherTeam = (runningTeam == TeamNS) and TeamNS or TeamEW,
            atoutColor = currentStake.atoutColor,
            contract = currentStake.contract,
            isCoinche = isCoinche
        }
    end
end

function RoundLoop(roundInfo, firstPlayerIndex)
    local runningTeam = roundInfo.team
    local otherTeam = roundInfo.otherTeam
    otherTeam.roundScore = 0
    runningTeam.roundScore = 0

    if runningTeam.roundScore > 81 and runningTeam.roundScore >
        roundInfo.contract then
        runningTeam.gameScore = runningTeam.gameScore + roundInfo.contract
    else
        otherTeam.gameScore = otherTeam.gameScore + 160
    end
end
