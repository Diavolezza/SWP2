//
//  GameCenterHelper.swift
//  Battle of the Stereotypes
//
//  Created by andre-jar on 30.04.18.
//  Copyright © 2018 andre-jar, Skeltek & AybuB. All rights reserved.
//

import Foundation
import GameKit

// Hilfsklasse, um Gamecenter Funktionalitäten einfacher zu nutzen
class GameCenterHelper: NSObject, GKGameCenterControllerDelegate,GKTurnBasedMatchmakerViewControllerDelegate,GKLocalPlayerListener {
    // ViewController, der darunterliegt. Sollte nicht mit nil belegt werden, da sonst die Anwendung abstürzt
    var underlyingViewController : UIViewController!
    // wartet auf ExchangeReply
    var isWaitingOnReply = false
    // aktuelles Match
    var currentMatch : GKTurnBasedMatch!
    // Variable ob GameCenter aktiv ist
    var gamecenterEnabled = false
    // ExchangeRequest
    var exchangeRequest = GameState.StructExchangeRequest()
    // Spielstatus
    var gameState : GameState.StructGameState = GameState.StructGameState()
    // Singleton Instanz
    static let sharedInstance = GameCenterHelper()
    
    
    private override init() {
        // private, da Singleton
    }
    
    // Gibt die GameCenterHelper Instanz zurück
    static func getInstance() -> GameCenterHelper
    {
        // TODO: Sicherstellen, dass die Instanz immer vorhanden ist, da sonst die Anwendung abstürzt
        if(sharedInstance.underlyingViewController == nil) {
            //print("Warnung! Kein View Controller für den GameCenterHelper gesetzt")
        }
        return GameCenterHelper.sharedInstance
    }
    
    // GKMatchmakerViewControllerDelegate Methoden
    
    // TurnBasedMatchMakerView abgebrochen
    func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        print("MatchMakerViewController abgebrochen")
        // TODO: Abbrechen sollte nicht erlaubt werden
        underlyingViewController.dismiss(animated:true, completion:nil)
        //findBattleMatch()
    }
    
    // TurnBasedMatchView fehlgeschlagen
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        // TODO: Hier bei Fehlschlag eventuell eine Fehler Meldung ausgeben und es erneut versuchen
        print("MatchMakerViewController fehlgeschlagen")
        underlyingViewController.dismiss(animated:true, completion:nil)
    }
    
    // TurnBasedMatchmakerView Match gefunden , bereits existierendes Spiel wird beigetreten
    private func turnBasedMatchmakerViewController(_ viewController: GKMatchmakerViewController, didFind match: GKTurnBasedMatch) {
        print("MatchMakerViewController Match gefunden")
        currentMatch = match
        // TODO: Ab hier ermöglichen das eigentliche Spiel zu spielen
    }
    
    // aufgerufen wenn der GameCenterViewController beendet wird
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        print("GameCenterViewController fertig")
        underlyingViewController.dismiss(animated: true, completion: nil)
    }
    
    // Funktion wird aufgerufen, wenn Spieler das Match verlässt
    func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, playerQuitFor match: GKTurnBasedMatch) {
        print("Match wurde beendet durch Player Quit")
        match.endMatchInTurn(withMatch: GameState.encodeGameState(gameState: gameState), completionHandler: nil)
    }
    
    // GKLocalPlayerListener Methoden
    
    // Methode zum Turnevent abhandeln
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        currentMatch=match
        // Abfrage nötig weil schon vor dem aktiven Match TurnEvents stattfinden können
        if(match.participants![0].lastTurnDate != nil) {
            let matchData = currentMatch.matchData
            currentMatch.loadMatchData(completionHandler: nil)
            gameState = GameState.decodeGameState(data: matchData!)
            if(isLocalPlayersTurn()) {
                // TODO: Hier anzeigen, das man am Zug ist
            }
        }
        print("Turn Event erhalten")
    }
    
    // Spieler erhält einen Exchange Request
    func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        print("Hier")
        let request : GameState.StructExchangeRequest = GameState.decodeExchangeRequest(data: exchange.data!)
        let forceCounter = request.forceCounter
        let angleForArrow = request.angleForArrow
        let damage = request.damage
        print("Request erhalten [forceCounter=" + String(forceCounter) + ", angleForArrow=" + String(angleForArrow) + ", damage=" + String(damage) + "]")
        
        // Hier Schuss simulieren
        GameViewController.germanMapScene.gameScene.forceCounter = forceCounter
        GameViewController.germanMapScene.gameScene.angleForArrow2 = CGFloat(angleForArrow)
            GameViewController.germanMapScene.gameScene.throwProjectile()
        //if(damage != 0) {
        // Schade Spieler
        //}
        
        var exchangeReply = GameState.StructExchangeReply()
        exchangeReply.projectileFired = true
        print("Versende Reply [projectileShot=" + String(exchangeReply.projectileFired) + "]")
        exchange.reply(withLocalizableMessageKey: "XY", arguments: ["XY","Y"], data: GameState.encodeExchangeReply(exchangeReply: exchangeReply), completionHandler: {(error: Error?) -> Void in
            if(error == nil ) {
                // Operation erfolgreich
            } else {
                print("Fehler beim ExchangeRequest beantworten")
                print(error as Any)
            }
        })
    }
    
    // Spieler erhält Information das der Exchange abgebrochen wurde
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        isWaitingOnReply = false
        print("Exchange abgebrochen")
    }
    
    // Spieler erhält eine Antwort auf einen Exchange Request
    func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply], forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        isWaitingOnReply = false
        for reply in replies {
            let reply = GameState.decodeExchangeReply(data: reply.data!)
            print("Reply erhalten [projectileShot=" + String(reply.projectileFired) + "]")

            // andre-jar: Was bedeutet diese Zeile?
            //exchange.status = "inactive" ??
            var tempExchangeArray = [GKTurnBasedExchange]()
            tempExchangeArray.append(exchange)
            currentMatch.saveMergedMatch(GameState.encodeGameState(gameState: gameState), withResolvedExchanges: tempExchangeArray, completionHandler: { (error: Error?) in
                if (error == nil) {
                    // Operation erfolgreich
                }
                else {
                    print("Fehler bei saveMergedMatch")
                    print(error as Any)
                }
            })
        }
        endTurn()
    }
    
    // Eigene Methoden
    
    // Gibt den Index des lokalen Spieler zum Match zurück. Falls der Spieler nicht teil des Matches ist oder das Spiel nicht läuft oder er nicht authentifiziert ist, gibt es -1 zurück
    func getIndexOfLocalPlayer() -> Int {
        if(!gamecenterIsActive() || !isGameRunning()) {
            print("Fehler: getIndexOfLocalPlayer: Game Center inactive or Game not running")
            return -1
        }
        for participant in currentMatch.participants! {
            if(participant.player?.playerID == GKLocalPlayer.localPlayer().playerID) {
                return currentMatch.participants!.index(of: participant)!
            }
        }
        return -1
    }
    
    // Gibt an ob der lokale Spieler gerade am Zug ist
    func isLocalPlayersTurn() -> Bool
    {
        if(!gamecenterIsActive() || !isGameRunning()) {
            print("Fehler: isLocalPlayersTurn: Game Center inactive or Game not running")
            if (!gamecenterIsActive()){
                findBattleMatch()
            } else {
                return false
            }
        }
        if(currentMatch.currentParticipant?.player?.playerID == GKLocalPlayer.localPlayer().playerID) {
            return true
        } else {
            print("Fehler: isLocalPlayersTurn: else-Error")
            return false
        }
    }

    // Authentifizierung des lokalen Spielers
    func authenticateLocalPlayer() {
        let localPlayer: GKLocalPlayer = GKLocalPlayer.localPlayer()
        
        localPlayer.authenticateHandler = {(ViewController, error) -> Void in
            if((ViewController) != nil) {
                // Zeige den Login Screen wenn der Spieler nicht eingeloggt ist
                print("Notification: authenticateLocalPlayer")
                self.underlyingViewController.present(ViewController!, animated: true, completion: nil)
            } else if (localPlayer.isAuthenticated) {
                // Wenn Spieler bereits authentifiziert und eingeloggt, lade MatchMaker und GameCenter Funktionen
                print("Notification: authenticateLocalPlayer: Spieler bereits authentifiziert")
                self.gamecenterEnabled = true
                localPlayer.unregisterAllListeners()
                localPlayer.register(self)
                self.findBattleMatch()
            } else {
                // Game center nicht auf aktuellem Gerät aktiviert
                self.gamecenterEnabled = false
                print("Fehler: authenticateLocalPlayer: Lokaler Spieler konnte nicht autentifiziert werden")
                print(error as Any)
            }
        }
    }
    
    // Prüft ob Gamecenter aktiv ist bzw. ob der Spieler sich eingeloggt hat und gibt false zurück wenn nicht
    func gamecenterIsActive() -> Bool
    {
        if(gamecenterEnabled == false) {
            print("Fehler: Spieler ist nicht eingeloggt")
            return false
        } else {
            return true
        }
    }
    
    // Prüft ob ein Spiel am Laufen ist und gibt false zurück wenn nicht
    func isGameRunning() -> Bool
    {
        if(currentMatch == nil) {
            print("Fehler: Aktion kann nicht ohne ein gestartetes Spiel zu haben ausgeführt werden")
            return false
        } else {
            return true
        }
    }
    
    // Erstelle ein Match Objekt und versuche einem Spiel beizutreten
    func findBattleMatch()
    {
        if(!gamecenterIsActive()) {
            print("Fehler: findBattleMatch: GameCenter inactive")
            return
        }
        print("Beitreten eines... Battle Match")
        let matchRequest=GKMatchRequest()
        matchRequest.maxPlayers=2
        matchRequest.minPlayers=2
        matchRequest.defaultNumberOfPlayers=2
        matchRequest.inviteMessage=GKLocalPlayer.localPlayer().displayName! + " würde gerne Battle of the Stereotypes mit dir spielen"
        let matchMakerViewController = GKTurnBasedMatchmakerViewController.init(matchRequest: matchRequest)
        matchMakerViewController.turnBasedMatchmakerDelegate=self as GKTurnBasedMatchmakerViewControllerDelegate
        underlyingViewController.present(matchMakerViewController, animated: true)
    }
    
    // Methode, wenn der lokale Spieler einen Exchange Request schicken will
    func sendExchangeRequest()
    {
        var nextParticipant : GKTurnBasedParticipant
        nextParticipant = currentMatch.participants![((getIndexOfLocalPlayer() + 1) % (currentMatch.participants?.count)!)]
        
        print("Sende Exchange Request [angleForArrow=" + String(exchangeRequest.angleForArrow) + ", damage=" + String(exchangeRequest.damage) + ", forceCounter=" + String(exchangeRequest.forceCounter) + "]")
        currentMatch.sendExchange(to: [nextParticipant], data: GameState.encodeExchangeRequest(exchangeRequest: exchangeRequest), localizableMessageKey: "XYZ", arguments: ["X","Y"], timeout: TimeInterval(5.0), completionHandler: {(exchangeReq: GKTurnBasedExchange?,error: Error?) -> Void in
            if(error == nil ) {
                // Operation erfolgreich
                self.isWaitingOnReply = true
            } else {
                print("[" + String(describing: self) + "]" + "Fehler beim ExchangeRequest senden")
                print(error as Any)
            }
        })
    }
    
    // Methode wenn der lokale Spieler seinen Zug beendet hat
    func endTurn()
    {
        if(!isGameRunning()) {
            return
        }
        print("Turn beenden")
        var nextParticipant : GKTurnBasedParticipant
        nextParticipant = currentMatch.participants![((getIndexOfLocalPlayer() + 1) % (currentMatch.participants?.count)!)]
        currentMatch.endTurn(withNextParticipants: [nextParticipant], turnTimeout: TimeInterval(5.0), match:         GameState.encodeGameState(gameState: gameState), completionHandler: { (error: Error?) in
            if(error == nil ) {
                // Operation erfolgreich
            } else {
                print("Fehler gefunden beim Turn beenden")
                print(error as Any)
            }
        })
    }
    
    // Temporäre Funktion um Matches vom GameCenter zu löschen
    func removeGames()
    {
        GKTurnBasedMatch.loadMatches(completionHandler: {(matches: [GKTurnBasedMatch]?, error: Error?) -> Void in
            if(matches == nil) {
                print("Keine Matches in denen der lokale Spieler beigetreten ist gefunden")
                return
            }
            print("Versuche Matches in denen der lokale Spieler beigetreten ist zu löschen...")
            for match in matches.unsafelyUnwrapped {
                print("Match Outcome setzen")
                for participant in match.participants! {
                    participant.matchOutcome = GKTurnBasedMatchOutcome.quit  }
                match.endMatchInTurn(withMatch: GameState.encodeGameState(gameState: self.gameState), completionHandler: {(error: Error?) -> Void in
                    print("Fehler in endMatch")
                    print(error as Any)
                })
                match.remove(completionHandler: {(error: Error?) -> Void in
                    print("Fehler in removeGame")
                    print(error as Any)
                })
            }
        })
    }
    
    // Beendet das Spiel
    func endGame()
    {
        currentMatch.endMatchInTurn(withMatch: GameState.encodeGameState(gameState: gameState), completionHandler: nil)
    }
    
    // Methode um die MatchOutcomes zu setzen, also das Ergebnis für den Spieler wie beispielsweise gewonnen oder verloren
    func setMatchOutcomes()
    {
        print("Versuche Match Outcomes zu setzen")
        for participant in currentMatch.participants! {
            participant.matchOutcome = GKTurnBasedMatchOutcome.none
            if(participant.player?.playerID == GKLocalPlayer.localPlayer().playerID && gameState.playerHealth[(currentMatch.participants?.index(of: participant))!] == 0) {
                participant.matchOutcome = GKTurnBasedMatchOutcome.lost
                currentMatch.endMatchInTurn(withMatch: GameState.encodeGameState(gameState: gameState), completionHandler: {(error: Error?) -> Void in
                    print("Error in endMatch")
                    print(error as Any)
                })
            }
        }
    }
}
