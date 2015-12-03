//
//  GameScene.swift
//  AlienConqueror
//
//  Created by Brad Flaugher on 6/22/15.
//  Copyright (c) 2015 Brad Flaugher. All rights reserved.
//

import SpriteKit
import UIKit
import AudioToolbox
import Darwin
import CoreMotion
import AVFoundation
import ImojiSDK

struct PhysicsCategory {
    static let Enemy : UInt32 = 1
    static let Boss : UInt32 = 2
    static let Bullet : UInt32 = 3
    static let Upgrade : UInt32 = 4
    static let Powerup : UInt32 = 5
    static let Player : UInt32 = 6
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Imoji setup
    private var session: IMImojiSession!
    var playerImoji = IMImojiObject()

    
    //startButton
    var startButton = UIButton()
    var restartButton = UIButton()
    var infButton = UIButton()
    var label = UILabel()
    var hsLabel = UILabel()
    var controlLabel = UILabel()
    var scoreLabel = UILabel()
    var pauseLabel = UILabel()
    var gameStarted = Bool()
    
    //sparkle
    var sparkle = Int()
    
    
    //pause
    var pauseButton = UIButton()
    var gameIsPaused = Bool()
    
    //Player
    var player = SKSpriteNode()
    
    //Health
    var maxHealth = Int()
    var health = Int()
    var score = Int()
    var level = Int()
    var powerup = Int()
    var infMode = Bool()
    
    //Bullet Texture
    var bulletTexture = String()
    
    //Timers for Bullets and Enemies
    var bulletTimer = NSTimer()
    var enemyTimer = NSTimer()
    var healthTimer = NSTimer()
    var powerupTimer = NSTimer()
    var backgroundTimer = NSTimer()
    var sparkleTimer = NSTimer()
    
    //Speed and Frequency
    var timeBetweenBullets = Double()
    var timeToShootBullets = Double()
    var timeBetweenEnemies = Double()
    var timeBetweenHealth = Double()
    var timeBetweenPowerups = Double()
    var timeToFlyUpgrades = Double()
    
    //accelerometer
    let motionManager: CMMotionManager = CMMotionManager()
    
    //"dpad"
    var padRight = Bool()
    var padLeft = Bool()

    //music
    var ThemePlayer = AVAudioPlayer()
    
    //*********************************************************************************************
    //*******************************INITIAL SETUP*************************************************
    //*********************************************************************************************
    override func didMoveToView(view: SKView) {
        startScreen()
        motionManager.startAccelerometerUpdates()
        NSLog("MOVING")
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        //UIApplicationDidEnterBackgroundNotification & UIApplicationWillEnterForegroundNotification shouldn't be quoted
        notificationCenter.addObserver(self, selector: "didEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: "didBecomeActive", name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "rotated", name: UIDeviceOrientationDidChangeNotification, object: nil)


    }
    
    
    func startScreen(){
    
        ThemeSound("6014")
        
        gameStarted = false
        padLeft = false
        padRight = false
        
        let screenWidth = self.view!.frame.size.width
        let screenHeight = self.view!.frame.size.height
        
        //Welcome Label
        let labelHeight = 300
        let labelWidth = 600
        
        label = UILabel(frame: CGRectMake( CGFloat(screenWidth / 2) - CGFloat(labelWidth / 2), CGFloat(screenHeight / 7) - CGFloat(labelHeight / 2), CGFloat(labelWidth), CGFloat(labelHeight)))
        //label.center = CGPointMake(CGFloat(screenWidth / 2) - CGFloat(labelWidth / 2), CGFloat(screenHeight / 4) - CGFloat(labelHeight / 2))
        label.textAlignment = NSTextAlignment.Center
        label.text = "6014: Space Shooter of The Future"
        label.textColor = UIColor.whiteColor()
        label.numberOfLines = 0
        label.font = UIFont(name: "Krungthep", size: 20)
        self.view!.addSubview(label)
        
        
        //High Score Label
        let hsLabelHeight = 300
        let hsLabelWidth = 600
        
        hsLabel = UILabel(frame: CGRectMake( CGFloat(screenWidth / 2) - CGFloat(hsLabelWidth / 2), CGFloat(screenHeight * 6 / 7) - CGFloat(hsLabelHeight / 2), CGFloat(hsLabelWidth), CGFloat(hsLabelHeight)))
        hsLabel.textAlignment = NSTextAlignment.Center
        hsLabel.textColor = UIColor.whiteColor()
        hsLabel.numberOfLines = 0
        hsLabel.font = UIFont(name: "Krungthep", size: 15)
        
        
        //high score
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        //display high score if one exists
        if let highscore = userDefaults.valueForKey("highscore") as? Int {
            // do something here when a highscore exists
            hsLabel.text = "Max Progress: \(Int((floor(Double(highscore) / 13.0)/50.0)*100))%"
            NSLog("Highscore \(highscore)")

        }
        else {
            // no highscore exists
            hsLabel.text = "Max Progress: 0%"
        }
        
        self.view!.addSubview(hsLabel)

        //High Score Label
        let controlLabelHeight = 300
        let controlLabelWidth = 200
        
        controlLabel = UILabel(frame: CGRectMake( CGFloat(screenWidth * 3 / 4) - CGFloat(controlLabelWidth / 2), CGFloat(screenHeight / 2) - CGFloat(controlLabelHeight / 2), CGFloat(controlLabelWidth), CGFloat(controlLabelHeight)))
        controlLabel.textAlignment = NSTextAlignment.Center
        controlLabel.textColor = UIColor.whiteColor()
        controlLabel.numberOfLines = 0
        controlLabel.font = UIFont(name: "Krungthep", size: 13)
        
        if(UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad){
            controlLabel.text = "Tap to steer\n✚ = health\n▲= upgrade"
        }
        else{
            controlLabel.text = "Tap to steer\nTilt to steer Fast!\n✚ = health\n▲= upgrade"
        }
        self.view!.addSubview(controlLabel)

        
        // start button
        let startButtonSize = 150
        startButton = UIButton(type: .Custom)
        startButton.frame = CGRectMake( CGFloat(screenWidth / 2) - CGFloat(startButtonSize / 2), CGFloat(screenHeight / 2) - CGFloat(startButtonSize / 2), CGFloat(startButtonSize), CGFloat(startButtonSize))
        startButton.layer.cornerRadius = 0.5 * startButton.bounds.size.width
        startButton.setImage(UIImage(named:"Start.png"), forState: .Normal)
        startButton.addTarget(self, action: "resetGameNormal", forControlEvents: .TouchUpInside)
        self.view!.addSubview(startButton)

        let infButtonSize = 50
        infButton = UIButton(type: .Custom)
        infButton.frame = CGRectMake( CGFloat(screenWidth / 4) - CGFloat(infButtonSize / 2), CGFloat(screenHeight / 2) - CGFloat(infButtonSize / 2), CGFloat(infButtonSize), CGFloat(infButtonSize))
        infButton.layer.cornerRadius = 0.5 * infButton.bounds.size.width
        infButton.setImage(UIImage(named:"Unld.png"), forState: .Normal)
        infButton.addTarget(self, action: "resetGameInf", forControlEvents: .TouchUpInside)
        self.view!.addSubview(infButton)
        
        
        //background
        self.scene?.backgroundColor=UIColor.blackColor()
        backgroundTimer = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: Selector("spawnStarsFast"), userInfo: nil, repeats: true)
        
    
    }

    func resetGameNormal(){
        infMode = false
        resetGame()
    }
    
    func resetGameInf(){
        infMode = true
        resetGame()
    }
    
    func resetGame(){
        startButton.removeFromSuperview()
        infButton.removeFromSuperview()
        label.removeFromSuperview()
        hsLabel.removeFromSuperview()
        controlLabel.removeFromSuperview()
        backgroundTimer.invalidate()
        self.removeAllChildren()
        ThemePlayer.pause()
        ThemeSound("6014play")
        
        //Set Initial Scores and Speeds level should be 0, health should be 3
        gameStarted = true
        score = 0
        level = 0
        powerup = 0
        maxHealth = 10
        health = maxHealth
        timeBetweenBullets = 0.25
        timeToShootBullets = 0.2
        timeBetweenEnemies = 0.32
        timeBetweenHealth = 5.5
        timeBetweenPowerups = 4.0
        timeToFlyUpgrades = 5.0
        gameIsPaused = false
        sparkle = 1
        
        
        // Score Label
        let labelHeight =  60
        let labelWidth = 100
        
        scoreLabel = UILabel(frame: CGRectMake(0, self.view!.frame.size.height - CGFloat(labelHeight), CGFloat(labelWidth), CGFloat(labelHeight)))
        scoreLabel.textAlignment = NSTextAlignment.Left
        if(infMode){
            scoreLabel.text = "Health: ∞\nLevel: \(level)/50\nScore: \(score)"
        }
        else{
            scoreLabel.text = "Health: \(health)\nLevel: \(level)/50\nScore: \(score)"
        }
        scoreLabel.textColor = UIColor.whiteColor()
        scoreLabel.alpha = 0.25
        scoreLabel.numberOfLines = 0
        scoreLabel.font = UIFont(name: "Krungthep", size: 12)
        self.view!.addSubview(scoreLabel)
        
        // Pause Label/Button
        let pauseLabelSize =  25
        let screenWidth = self.view!.frame.size.width
        let screenHeight = self.view!.frame.size.height
        pauseButton = UIButton(type: .Custom)
        pauseButton.frame = CGRectMake( CGFloat(screenWidth * 95 / 100) - CGFloat(pauseLabelSize / 2), CGFloat(screenHeight * 95 / 100) - CGFloat(pauseLabelSize / 2), CGFloat(pauseLabelSize), CGFloat(pauseLabelSize))
        pauseButton.layer.cornerRadius = 0.5 * pauseButton.bounds.size.width
        pauseButton.alpha = 0.25
        pauseButton.setImage(UIImage(named:"Pause.png"), forState: .Normal)
        pauseButton.addTarget(self, action: "pause", forControlEvents: .TouchUpInside)
        self.view!.addSubview(pauseButton)
        
        
        var imojiSuccess = false
        
        //get imoji for initial setup, first search
        session.searchImojisWithTerm("kanye", offset: 0, numberOfResults: 1,
            resultSetResponseCallback:{ resultCount, error in
            if error == nil {
            }
            else{
                imojiSuccess = false
            }
            },
            imojiResponseCallback:{ imoji,index,error in
                if error == nil {
                    self.playerImoji = imoji!
                }
                else{
                    imojiSuccess = false
                }
        })
        
        //now render the imoji
        session.renderImoji(playerImoji, options: IMImojiObjectRenderingOptions(renderSize: IMImojiObjectRenderSize.SizeThumbnail), callback:{ image, error in
            if error == nil {
                let texture = SKTexture(image: image!)
                self.player = SKSpriteNode(texture: texture)
                imojiSuccess = true
            }
            else{
                imojiSuccess = false
            }
        })
        
        //if it didn't work, use the a default sprite
        if(!imojiSuccess){
            self.player = SKSpriteNode(imageNamed: "g3.png")
        }
        
        //Set inital bullet sprite
        bulletTexture = "Bullet.png"
        
        //Set the background color and add an SKEmitterNode
        self.scene?.backgroundColor=UIColor.blackColor()
        
        //Setup the Player/Ship and the physics of the player
        physicsWorld.contactDelegate=self
        player.position = CGPointMake(self.size.width / 2, self.size.height / 7.5)
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.dynamic=true
        player.physicsBody?.mass = 0.01
        self.addChild(player)
        
        if(infMode==true){
            sparkleTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenBullets/4, target: self, selector: Selector("sparklePlayer"), userInfo: nil, repeats: true)
        }
    
    
        //Setup a stream of enemies and bullets
        bulletTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenBullets, target: self, selector: Selector("spawnBullets"), userInfo: nil, repeats: true)
        enemyTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenEnemies, target: self, selector: Selector("spawnEnemies"), userInfo: nil, repeats: true)
        healthTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenHealth, target: self, selector: Selector("spawnHealth"), userInfo: nil, repeats: true)
        powerupTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenPowerups, target: self, selector: Selector("spawnPowerups"), userInfo: nil, repeats: true)
        backgroundTimer = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: Selector("spawnStars"), userInfo: nil, repeats: true)

        setupEnemy("6.png", enemyHealth: 2, positionType: 4, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
        setupEnemy("0.png", enemyHealth: 2, positionType: 2, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
        setupEnemy("1.png", enemyHealth: 2, positionType: 3, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
        setupEnemy("4.png", enemyHealth: 2, positionType: 5, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)

        
    }
    
    func endGame(){
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        //set high score
        if let highscore = userDefaults.valueForKey("highscore") as? Int {
            // do something here when a highscore exists
            if (score > highscore){
                userDefaults.setValue(score, forKey: "highscore")
                userDefaults.synchronize()
            }
        }
        else {
            // no highscore exists
            userDefaults.setValue(score, forKey: "highscore")
            userDefaults.synchronize()
        }
        
        //remove all Children, Actions, and Timers
        let children = self.children
        
        for child in children {
            if let unwrappedCatBitMask = child.physicsBody?.categoryBitMask{
                if (unwrappedCatBitMask == PhysicsCategory.Enemy || unwrappedCatBitMask == PhysicsCategory.Boss){
                    let enemy = child as! BJEnemy
                    enemy.removeFromParent()
                }
            }
            else{
                child.removeFromParent()
            }
            
        }
        
        self.removeAllChildren()
        self.removeAllActions()
        
        //this shouldnt need to be called, make sure
        player.removeFromParent()
        
        //invalidate all timers
        healthTimer.invalidate()
        powerupTimer.invalidate()
        backgroundTimer.invalidate()
        bulletTimer.invalidate()
        enemyTimer.invalidate()
        sparkleTimer.invalidate()
        NSLog("GAME OVER!")
        scoreLabel.removeFromSuperview()
        pauseButton.removeFromSuperview()
        pauseLabel.removeFromSuperview()
        restartButton.removeFromSuperview()
        
        //TODO get rid of this. have an intermediate step that has a button
        ThemePlayer.pause()
        startScreen()
    }
    
    func ThemeSound(file: String) {
        if let path = NSBundle.mainBundle().pathForResource(file, ofType: "aiff") {
            let enemy1sound = NSURL(fileURLWithPath:path)
            NSLog("\(enemy1sound)")
            
            var error:NSError?
            do {
                ThemePlayer = try AVAudioPlayer(contentsOfURL: enemy1sound)
            } catch let error1 as NSError {
                error = error1
                NSLog("\(error)")
            }

            if(!ThemePlayer.playing){
                ThemePlayer.prepareToPlay()
                ThemePlayer.numberOfLoops = -1
                ThemePlayer.play()
            }
        
        }
    }
    //*********************************************************************************************
    //*******************************PAUSING RESTARTING********************************************
    //*********************************************************************************************
    
    func pause(){
        if (gameIsPaused==true){
            makeUnPaused()
        }
        else if (gameIsPaused==false){
            makePaused()
            
        }
    }
    
    func makePaused(){
        stopAllTimers()
        gameIsPaused = true
        //High Score Label
        let pauseLabelHeight = 250
        let pauseLabelWidth = 500
        
        player.removeFromParent()
        
        let screenWidth = self.view!.frame.size.width
        let screenHeight = self.view!.frame.size.height
        
        pauseLabel = UILabel(frame: CGRectMake( CGFloat(screenWidth / 2) - CGFloat(pauseLabelWidth / 2), CGFloat(screenHeight / 3) - CGFloat(pauseLabelHeight / 2), CGFloat(pauseLabelWidth), CGFloat(pauseLabelHeight)))
        pauseLabel.textAlignment = NSTextAlignment.Center
        pauseLabel.textColor = UIColor.whiteColor()
        pauseLabel.numberOfLines = 0
        pauseLabel.font = UIFont(name: "Krungthep", size: 75)
        pauseLabel.text = "PAUSED"
        pauseButton.setImage(UIImage(named:"Resume.png"), forState: .Normal)
        self.view!.addSubview(pauseLabel)
        ThemePlayer.pause()
        
        let startButtonSize = 100
        restartButton = UIButton(type: .Custom)
        restartButton.frame = CGRectMake( CGFloat(screenWidth / 2) - CGFloat(startButtonSize / 2), CGFloat(screenHeight * 2 / 3) - CGFloat(startButtonSize / 2), CGFloat(startButtonSize), CGFloat(startButtonSize))
        restartButton.layer.cornerRadius = 0.5 * restartButton.bounds.size.width
        restartButton.setImage(UIImage(named:"Quit.png"), forState: .Normal)
        restartButton.addTarget(self, action: "endGame", forControlEvents: .TouchUpInside)
        self.view!.addSubview(restartButton)
        
    }
    
    
    func makeUnPaused(){
        restartAllTimers()
        gameIsPaused = false
        pauseButton.setImage(UIImage(named:"Pause.png"), forState: .Normal)
        pauseLabel.removeFromSuperview()
        restartButton.removeFromSuperview()
        
        player.position = CGPointMake(self.size.width / 2, self.size.height / 7.5)
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = PhysicsCategory.Player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
        player.physicsBody?.collisionBitMask = 0
        player.physicsBody?.dynamic=true
        player.physicsBody?.mass = 0.01
        self.addChild(player)
        
        ThemePlayer.play()
    }
    
    func stopAllTimers(){
        //stop all timers
        bulletTimer.invalidate()
        enemyTimer.invalidate()
        healthTimer.invalidate()
        powerupTimer.invalidate()
        backgroundTimer.invalidate()
        sparkleTimer.invalidate()
        padLeft = false
        padRight = false
        
        //stop all enemy bullet timers
        //remove all Children, Actions, and Timers
        let children = self.children
        
        for child in children {
            if let unwrappedCatBitMask = child.physicsBody?.categoryBitMask{
                if (unwrappedCatBitMask == PhysicsCategory.Enemy || unwrappedCatBitMask == PhysicsCategory.Boss){
                    let enemy = child as! BJEnemy
                    enemy.removeFromParent()
                }
            }
            else{
                child.removeFromParent()
            }
            
        }
    }
    
    func restartAllTimers(){
        padLeft = false
        padRight = false
        
        if(gameStarted){
            bulletTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenBullets, target: self, selector: Selector("spawnBullets"), userInfo: nil, repeats: true)
            healthTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenHealth, target: self, selector: Selector("spawnHealth"), userInfo: nil, repeats: true)
            powerupTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenPowerups, target: self, selector: Selector("spawnPowerups"), userInfo: nil, repeats: true)
            backgroundTimer = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: Selector("spawnStars"), userInfo: nil, repeats: true)
            if(infMode==true){
                sparkleTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenBullets/4, target: self, selector: Selector("sparklePlayer"), userInfo: nil, repeats: true)
            }
            else{
                checkPowerup()
            }
            generateEnemies()
        }
        else{
            startScreen()
        }
    }
    
    func didEnterBackground() {
        if (!gameIsPaused && gameStarted){
            makePaused()
        }
        else if(!gameStarted){
            stopAllTimers()
        }
    }
    
    func didBecomeActive() {
        if(!gameStarted){
            backgroundTimer = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: Selector("spawnStarsFast"), userInfo: nil, repeats: true)
        }
        
    }
    
    func rotated()
    {
        //        if(UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation))
        //        {
        //            println("landscape")
        //        }
        //
        //        if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation))
        //        {
        //            println("Portrait")
        //        }
        
        if(gameStarted==false){
            //the game plays fine regardless of orientation ,just the start screen
            //is messed up, so remake that if the orientation changes
            infButton.removeFromSuperview()
            startButton.removeFromSuperview()
            label.removeFromSuperview()
            hsLabel.removeFromSuperview()
            controlLabel.removeFromSuperview()
            backgroundTimer.invalidate()
            self.removeAllChildren()
            startScreen()
        }
        else{
            scoreLabel.removeFromSuperview()
            pauseButton.removeFromSuperview()
            
            // Score Label
            let labelHeight =  60
            let labelWidth = 100
            
            scoreLabel = UILabel(frame: CGRectMake(0, self.view!.frame.size.height - CGFloat(labelHeight), CGFloat(labelWidth), CGFloat(labelHeight)))
            scoreLabel.textAlignment = NSTextAlignment.Left
            if(infMode){
                scoreLabel.text = "Health: ∞\nLevel: \(level)/50\nScore: \(score)"
            }
            else{
                scoreLabel.text = "Health: \(health)\nLevel: \(level)/50\nScore: \(score)"
            }
            scoreLabel.textColor = UIColor.whiteColor()
            scoreLabel.alpha = 0.25
            scoreLabel.numberOfLines = 0
            scoreLabel.font = UIFont(name: "Krungthep", size: 12)
            self.view!.addSubview(scoreLabel)
            
            // Pause Label/Button
            let pauseLabelSize =  25
            let screenWidth = self.view!.frame.size.width
            let screenHeight = self.view!.frame.size.height
            pauseButton = UIButton(type: .Custom)
            pauseButton.frame = CGRectMake( CGFloat(screenWidth * 95 / 100) - CGFloat(pauseLabelSize / 2), CGFloat(screenHeight * 95 / 100) - CGFloat(pauseLabelSize / 2), CGFloat(pauseLabelSize), CGFloat(pauseLabelSize))
            pauseButton.layer.cornerRadius = 0.5 * pauseButton.bounds.size.width
            pauseButton.alpha = 0.25
            if(gameIsPaused){
                pauseButton.setImage(UIImage(named:"Resume.png"), forState: .Normal)
            }
            else{
                pauseButton.setImage(UIImage(named:"Pause.png"), forState: .Normal)
            }
            pauseButton.setImage(UIImage(named:"Pause.png"), forState: .Normal)
            pauseButton.addTarget(self, action: "pause", forControlEvents: .TouchUpInside)
            self.view!.addSubview(pauseButton)
            
        }
    }
    
    
    //*********************************************************************************************
    //*******************************LEVEL CHANGIN*************************************************
    //*********************************************************************************************
    
    func incrementLevel(){
        
        let oldLevel = level
        let shouldBeLevel = Int(floor(Double(score) / 13.0))
        
        if(shouldBeLevel != oldLevel)
        {
            level = shouldBeLevel
            randomColorScene()
            spawnLevelNumber()
            enemyTimer.invalidate()
            generateEnemies()
        }
    }
    
    
    func generateEnemies(){
        //boss levels go very slow
        if(level % 5 == 4){
            setupEnemy("boss.png", enemyHealth: 70 + Int(120 * (level/50)), positionType: 6, pathType: 5, gunType: 1, timeToFlyEnemies: 30.0, points: 14, isBoss: true)
            
            enemyTimer = NSTimer.scheduledTimerWithTimeInterval(0.5 , target: self, selector: Selector("spawnEnemies"), userInfo: nil, repeats: true)
        }
            //asteroid levels go very fast
        else if(level % 5 == 0 && level < 50){
            timeBetweenEnemies = 0.2 + Double((50-level)/50) * 0.4
            enemyTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenEnemies , target: self, selector: Selector("spawnEnemies"), userInfo: nil, repeats: true)
        }
            //other levels with gunners go a little slower
        else{
            timeBetweenEnemies = 0.5 + Double((50-level)/50) * 1.0
            enemyTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenEnemies , target: self, selector: Selector("spawnEnemies"), userInfo: nil, repeats: true)
        }
    }
    
    func randomColorScene(){
        
        var red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        var green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        var blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        
        //make sure the background is not too light
        while ( (red + green + blue) < 0.50 ){
            red = CGFloat(Float(0.1) + Float(arc4random()) / Float(UINT32_MAX))
            green = CGFloat(Float(0.1) + Float(arc4random()) / Float(UINT32_MAX))
            blue = CGFloat(Float(0.1) + Float(arc4random()) / Float(UINT32_MAX))
        }
        
        self.scene?.backgroundColor=UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    
    //*********************************************************************************************
    //*******************************ENEMIES*******************************************************
    //*********************************************************************************************
    
    func spawnEnemies(){
        
        //defaults
        var timeToFlyEnemies = 3.0
        var enemyTexture = "b0.png"
        var positionType = 0
        var pathType = 0
        var enemyHealth = 1
        var gunType = 0
        var points = 1
        
        //each level has certain types of enemies
        if(level % 5 == 0 && level < 50){
            let EnemyArray = ["b0.png","b1.png"]
            let randomIndex = Int(arc4random_uniform(UInt32(EnemyArray.count)))
            enemyTexture = EnemyArray[randomIndex]

        }
        else if(level % 5 == 1 && level < 50){
            let EnemyArray = ["b0.png","b1.png","b0.png","b1.png","b2.png"]
            let randomIndex = Int(arc4random_uniform(UInt32(EnemyArray.count)))
            enemyTexture = EnemyArray[randomIndex]
            
            if(enemyTexture=="b2.png"){
                timeToFlyEnemies = 10 - Double(1 * (level/50))
                pathType = 3
            }

        }
        else if(level % 5 == 2 && level < 50){
            let EnemyArray = ["b0.png","b1.png","b0.png","b1.png","b2.png","b3.png","b3.png"]
            let randomIndex = Int(arc4random_uniform(UInt32(EnemyArray.count)))
            enemyTexture = EnemyArray[randomIndex]
            
            if(enemyTexture=="b2.png"){
                timeToFlyEnemies = 4.0 - Double(2 * (level/50))
                pathType = 4
            }
        }
        else if(level % 5 == 3 && level < 50){
            let EnemyArray = ["b0.png","b1.png","b1.png","b2.png"]
            let randomIndex = Int(arc4random_uniform(UInt32(EnemyArray.count)))
            enemyTexture = EnemyArray[randomIndex]
            
            if(enemyTexture=="b2.png"){
                timeToFlyEnemies = 2.0 - Double(1 * (level/50))
                pathType = 2
            }

        }
        else if(level % 5 == 4){
            //boss levels have only b0's around cept for the boss which is spawned manually/not by a timer
            let EnemyArray = ["b0.png","b0.png","b0.png","b1.png"]
            let randomIndex = Int(arc4random_uniform(UInt32(EnemyArray.count)))
            enemyTexture = EnemyArray[randomIndex]
            points = 0
        }
        else{
            //every level after 50 cept the boss ones are totally random AND EVERYTHING SHOOTS
            let EnemyArray = ["b0.png","b1.png","b2.png","b3.png"]
            let randomIndex = Int(arc4random_uniform(UInt32(EnemyArray.count)))
            enemyTexture = EnemyArray[randomIndex]
            enemyTexture = EnemyArray[randomIndex]
            pathType = Int(arc4random_uniform(UInt32(5)))
            positionType = Int(arc4random_uniform(UInt32(5)))
            gunType = 1
        }
        
        
        //enemy heatlh and gun types are the same across levels
        if(enemyTexture=="b0.png" && level < 50){
            timeToFlyEnemies = 2.5 - Double(1 * (level/50))
            enemyHealth = 2 + Int(2 * (level/50))
            gunType = 0
        }
        else if(enemyTexture=="b1.png"){
            timeToFlyEnemies = 3.0 - Double(1 * (level/50))
            enemyHealth = 2 + Int(3 * (level/50))
            gunType = 0
        }
        else if(enemyTexture=="b2.png"){
            enemyHealth = 5 + Int(3 * (level/50))
            gunType = 1
        }
        else if(enemyTexture=="b3.png"){
            timeToFlyEnemies = 6.0
            enemyHealth = 3 + Int(2 * (level/50))
            gunType = 3
        }
    
    
        setupEnemy(enemyTexture, enemyHealth: enemyHealth, positionType: positionType, pathType: pathType, gunType: gunType, timeToFlyEnemies: timeToFlyEnemies, points: points, isBoss: false)
        
    }
    
    func spawnLevelNumber(){
        
        if( ((level / 10) % 10) > 0){
            setupEnemy("\(((level / 10) % 10)).png", enemyHealth: 7, positionType: 2, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
            setupEnemy("\((level % 10)).png", enemyHealth: 7, positionType: 3, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
        }
        else if( level < 10){
            setupEnemy("\((level % 10)).png", enemyHealth: 7, positionType: 3, pathType: 0, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
        }
        else if( level > 100){
            setupEnemy("Q.png", enemyHealth: 10, positionType: 1, pathType: 3, gunType: 0, timeToFlyEnemies: 3.0, points: 0, isBoss: false)
        }
        
    }
    
    func setupEnemy(enemyTexture: String, enemyHealth: Int, positionType: Int, pathType: Int, gunType: Int, timeToFlyEnemies: Double, points: Int, isBoss: Bool){
        //setup the enemy
        let enemy = BJEnemy(imageNamed:enemyTexture, health: enemyHealth, points: points )
        
        
        //starting position of the enemy if specified overrides the rest of this shit
        if( positionType == 0){
            enemy.position = CGPoint(x : CGFloat(arc4random_uniform(UInt32(self.size.width))), y : self.size.height + enemy.size.height)
        }
        else if (positionType == 1)
        {
            enemy.position = CGPoint(x : self.size.width * 0.50 - enemy.size.width, y : self.size.height + enemy.size.height)
        }
        else if (positionType == 2)
        {
            enemy.position = CGPoint(x : self.size.width * 0.55 - enemy.size.width, y : self.size.height + enemy.size.height)
        }
        else if (positionType == 3)
        {
            enemy.position = CGPoint(x : self.size.width * 0.65 - enemy.size.width, y : self.size.height + enemy.size.height)
        }
        else if (positionType == 4)
        {
            enemy.position = CGPoint(x : self.size.width * 0.45 - enemy.size.width, y : self.size.height + enemy.size.height)
        }
        else if (positionType == 5)
        {
            enemy.position = CGPoint(x : self.size.width * 0.75 - enemy.size.width, y : self.size.height + enemy.size.height)
        }
        else if (positionType == 6)
        {
            enemy.position = CGPoint(x : self.size.width * 0.50, y : self.size.height + enemy.size.height)
        }
        
        
        //setup physics and collision testing
        enemy.physicsBody = SKPhysicsBody(rectangleOfSize: enemy.size)
        if(isBoss){
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.Boss
        }
        else{
            enemy.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
        }
        enemy.physicsBody?.contactTestBitMask = PhysicsCategory.Bullet
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.collisionBitMask = 0
        enemy.physicsBody?.dynamic = true
        
        if(pathType==0){
            //straight line downward
            let action = SKAction.moveToY(0 - enemy.size.height, duration: timeToFlyEnemies)
            let actionDone = SKAction.removeFromParent()
            enemy.runAction(SKAction.sequence([action,actionDone]))
        }
        else if (pathType==1){
            //across like a carosel (use for bosses)
            enemy.position = CGPoint(x: 0,y: 239)
            let path = UIBezierPath()
            path.moveToPoint(CGPoint(x: 0,y: 239))
            path.addCurveToPoint(CGPoint(x: 1000, y: 239), controlPoint1: CGPoint(x: 136, y: 373), controlPoint2: CGPoint(x: 178, y: 110))
            
            let action = SKAction.followPath(path.CGPath, duration: timeToFlyEnemies)
            let actionDone = SKAction.removeFromParent()
            enemy.runAction(SKAction.sequence([action,actionDone]))
        }
        else if (pathType==2){
            //direct line to player
            let action = SKAction.moveTo(player.position, duration: timeToFlyEnemies * Double(1 - ((player.position.y)/self.size.height)))
            let action2 = SKAction.moveToY(0 - enemy.size.height, duration: timeToFlyEnemies * Double((player.position.y)/self.size.height))
            let actionDone = SKAction.removeFromParent()
            enemy.runAction(SKAction.sequence([action,action2,actionDone]))
        }
        else if (pathType==3){
            //random x but straight down in 6 steps
            let steps = Int(6)
            let action1 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.40), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration: timeToFlyEnemies / Double(steps))
            let action2 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.50), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration:  timeToFlyEnemies / Double(steps))
            let action3 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.60), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration:  timeToFlyEnemies / Double(steps))
            let action4 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.70), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration: timeToFlyEnemies / Double(steps))
            let action5 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.80), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration:  timeToFlyEnemies / Double(steps))
            let action6 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.90), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration:  timeToFlyEnemies / Double(steps))
            let actionDone = SKAction.removeFromParent()
            enemy.runAction(SKAction.sequence([action1,action2,action3,action4,action5,action6,actionDone]))
        }
        else if (pathType==4){
            //heat seeking missle, wide (right or left at random) then straight to player, probably best to start from middle on this one
            let steps = Int(2)
            let randnum = Float(arc4random()) / Float(UINT32_MAX)
            var action1 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.60), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration: timeToFlyEnemies / Double(steps))
            
            if(randnum < 0.5){
                action1 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.10), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration: timeToFlyEnemies / Double(steps))
            }
            
            NSLog("\(Double((self.size.height * 0.5 - player.position.y)/self.size.height))")
            NSLog("\(Double((player.position.y)/self.size.height))")

            
            let action2 = SKAction.moveTo(player.position, duration: timeToFlyEnemies * Double((self.size.height * 0.5 - player.position.y)/self.size.height))
            let action3 = SKAction.moveToY(0 - enemy.size.height, duration: timeToFlyEnemies * Double((player.position.y)/self.size.height) )

            let actionDone = SKAction.removeFromParent()
            enemy.runAction(SKAction.sequence([action1,action2,action3,actionDone]))
        }
        else if (pathType==5){
            //BOSS. comes down, goes left to right a couple times... then flies through, best to start this from the middle too.
            //also should be longer than 10 seconds total time to fly
            let steps = Int(9)
            let action1 = SKAction.moveByX(0.0, y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration: 0.5 )
            let action2 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.30), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration:  0.5)
            let action3 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.30), y: CGFloat(CGFloat((self.size.height * -1) - enemy.size.height) / CGFloat(steps)),duration:  (timeToFlyEnemies-1.0) / Double(steps))
            let action4 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.30), y: 0.0,duration: (timeToFlyEnemies-1.0) / Double(steps))
            let action5 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.30), y: 0.0,duration:  (timeToFlyEnemies-1.0) / Double(steps))
            let action6 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(-0.30), y: 0.0,duration: (timeToFlyEnemies-1.0) / Double(steps))
            let action7 = SKAction.moveByX(CGFloat(arc4random_uniform(UInt32(self.size.width))) * CGFloat(0.30), y: 0.0,duration:  (timeToFlyEnemies-1.0) / Double(steps))
            let action8 = SKAction.moveTo(player.position, duration: (timeToFlyEnemies-1.0) / Double(steps))
            let action9 = SKAction.moveToY(0 - enemy.size.height, duration: (timeToFlyEnemies-1.0) / Double(steps) )

            enemy.runAction(SKAction.sequence([action1,action2,action3,action4,action5,action6,action7,action8,action9]))
        }
        
        
        if(gunType==1){
            //this first parameter (0.75) is the time between enemy bullets
            enemy.gunTimer = NSTimer.scheduledTimerWithTimeInterval(0.75, target: self, selector: Selector("spawnEnemyBullets:"), userInfo: enemy, repeats: true)
        }
        else if (gunType==3){
            //this first parameter (1.0) is the time between enemy bullets
            enemy.gunTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("spawnEnemyBullets3:"), userInfo: enemy, repeats: true)
        }
        
        self.addChild(enemy)
    }
    
    class BJEnemy : SKSpriteNode
    {
        var health = Int()
        var gunTimer = NSTimer()
        var points = Int()
        
        override init(texture: SKTexture?, color: UIColor, size: CGSize) {
            self.health = 1
            super.init(texture: texture, color: color, size: size)
        }
        
        convenience init(imageNamed name: String, health: Int, points: Int)
        {
            let texture = SKTexture(imageNamed: name)
            self.init(texture: texture)
            self.health = health
            self.points = points
        }
        
        required init?(coder aDecoder: NSCoder){
            super.init(coder: aDecoder)
        }
        
        override func removeFromParent(){
            gunTimer.invalidate()
            super.removeFromParent()
        }
    }
    
    func spawnEnemyBullets3(timer: NSTimer){
        
        let enemyTexture = "Bullet3.png"
        let enemyHealth = 1
        let parent = timer.userInfo as! BJEnemy
        
        //setup the bullet, which is just another enemy
        let enemyBullet = BJEnemy(imageNamed:enemyTexture, health: enemyHealth, points: 0)
        
        //THIS NEEDS TO BE PASSED IN
        enemyBullet.position = parent.position
        
        //setup physics and collision testing
        enemyBullet.physicsBody = SKPhysicsBody(rectangleOfSize: enemyBullet.size)
        enemyBullet.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
        enemyBullet.physicsBody?.contactTestBitMask = PhysicsCategory.Bullet
        enemyBullet.physicsBody?.affectedByGravity = false
        enemyBullet.physicsBody?.collisionBitMask = 0
        enemyBullet.physicsBody?.dynamic = false
        
        //straight line downward
        let action = SKAction.moveToY(0 - enemyBullet.size.height, duration: 0.2)
        let actionDone = SKAction.removeFromParent()
        enemyBullet.runAction(SKAction.sequence([action,actionDone]))
        
        self.addChild(enemyBullet)
    }
    
    
    
    func spawnEnemyBullets(timer: NSTimer){
        
        let enemyTexture = "Bullet.png"
        let enemyHealth = 1
        let parent = timer.userInfo as! BJEnemy
        
        //setup the bullet, which is just another enemy
        let enemyBullet = BJEnemy(imageNamed:enemyTexture, health: enemyHealth, points: 0)
        
        //THIS NEEDS TO BE PASSED IN
        enemyBullet.position = parent.position
        
        //setup physics and collision testing
        enemyBullet.physicsBody = SKPhysicsBody(rectangleOfSize: enemyBullet.size)
        enemyBullet.physicsBody?.categoryBitMask = PhysicsCategory.Enemy
        enemyBullet.physicsBody?.contactTestBitMask = PhysicsCategory.Bullet
        enemyBullet.physicsBody?.affectedByGravity = false
        enemyBullet.physicsBody?.collisionBitMask = 0
        enemyBullet.physicsBody?.dynamic = false
        
        //straight line downward
        let action = SKAction.moveToY(0 - enemyBullet.size.height, duration: 0.2)
        let actionDone = SKAction.removeFromParent()
        enemyBullet.runAction(SKAction.sequence([action,actionDone]))
        
        self.addChild(enemyBullet)
    }
    
    func hurtEnemy(enemy: BJEnemy){
        enemy.health=enemy.health-1
        
        //If an Enemy is dead, remove it and increment the score
        if(enemy.health <= 0){
            score = score + enemy.points
            enemy.removeFromParent()
            incrementLevel()
            if(infMode){
                scoreLabel.text = "Health: ∞\nLevel: \(level)/50\nScore: \(score)"
            }
            else{
                scoreLabel.text = "Health: \(health)\nLevel: \(level)/50\nScore: \(score)"
            }
            NSLog("SCORE = \(score)")
        }
    }
    
    //*********************************************************************************************
    //*******************************HEALTH********************************************************
    //*********************************************************************************************
    
    func spawnHealth(){
        
        //only send health if it's needed
        if(health < maxHealth){
            //setup the enemy
            let upgrade = SKSpriteNode(imageNamed:"Upgrade.png")
            
            //put the enemy at a random point in the width of the screen, starting at the top (self.size.height))
            upgrade.position = CGPoint(x : CGFloat(arc4random_uniform(UInt32(self.size.width))), y : self.size.height)
            
            //setup physics and collision testing
            upgrade.physicsBody = SKPhysicsBody(rectangleOfSize: upgrade.size)
            upgrade.physicsBody?.categoryBitMask = PhysicsCategory.Upgrade
            upgrade.physicsBody?.contactTestBitMask = PhysicsCategory.Player
            upgrade.physicsBody?.affectedByGravity = false
            upgrade.physicsBody?.collisionBitMask = 0
            upgrade.physicsBody?.dynamic = true
            
            //Move then remove... TODO change speed of movement as levels get harder
            let action = SKAction.moveToY(0, duration: timeToFlyUpgrades)
            let actionDone = SKAction.removeFromParent()
            upgrade.runAction(SKAction.sequence([action,actionDone]))
            
            self.addChild(upgrade)
        }
    }
    
    func collisionWithHealth(upgrade: SKSpriteNode,player: SKSpriteNode){
        
        upgrade.removeFromParent()
        
        if(health < maxHealth){
            health=health+1
            checkHealth(player)
        }
    }
    
    //*********************************************************************************************
    //*******************************POWERUPS******************************************************
    //*********************************************************************************************
    
    func spawnPowerups(){
        
        //only spawn powerups if they're needed
        if(powerup < 3){
            //setup the enemy
            let upgrade = SKSpriteNode(imageNamed:"PowerUp.png")
            
            //put the enemy at a random point in the width of the screen, starting at the top (self.size.height))
            upgrade.position = CGPoint(x : CGFloat(arc4random_uniform(UInt32(self.size.width))), y : self.size.height)
            
            //setup physics and collision testing
            upgrade.physicsBody = SKPhysicsBody(rectangleOfSize: upgrade.size)
            upgrade.physicsBody?.categoryBitMask = PhysicsCategory.Powerup
            upgrade.physicsBody?.contactTestBitMask = PhysicsCategory.Player
            upgrade.physicsBody?.affectedByGravity = false
            upgrade.physicsBody?.collisionBitMask = 0
            upgrade.physicsBody?.dynamic = true
            
            //Move then remove... TODO change speed of movement as levels get harder
            let action = SKAction.moveToY(0, duration: timeToFlyUpgrades)
            let actionDone = SKAction.removeFromParent()
            upgrade.runAction(SKAction.sequence([action,actionDone]))
            
            self.addChild(upgrade)
        }
    }
    
    func collisionWithPowerup(upgrade: SKSpriteNode,player: SKSpriteNode){
        
        upgrade.removeFromParent()
        powerup=powerup+1
        checkPowerup()
    }
    
    func checkPowerup(){
        
        if(powerup < 0){
            powerup = 0
        }
        
        if (powerup == 0){
            timeBetweenBullets = 0.25
            bulletTexture="Bullet.png"
        }
        else if (powerup == 1){
            timeBetweenBullets = 0.15
            bulletTexture="Bullet.png"
        }
        else if (powerup == 2){
            timeBetweenBullets = 0.1
            bulletTexture="Bullet2.png"
            
            if(infMode==false){
                sparkleTimer.invalidate()
            }

        }
        else if(powerup == 3){
            health = 10
            if(infMode==false){
                sparkleTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenBullets/4, target: self, selector: Selector("sparklePlayer"), userInfo: nil, repeats: true)
            }
        }

        bulletTimer.invalidate()
        bulletTimer = NSTimer.scheduledTimerWithTimeInterval(timeBetweenBullets, target: self, selector: Selector("spawnBullets"), userInfo: nil, repeats: true)
    }
    
    //*********************************************************************************************
    //*******************************PLAYER********************************************************
    //*********************************************************************************************
    
    
    func sparklePlayer(){
        if(sparkle==1){
            player.texture = SKTexture(imageNamed: "g8.png")
            sparkle = sparkle + 1
        }
        else if (sparkle==2){
            player.texture = SKTexture(imageNamed: "g4.png")
            sparkle = sparkle + 1
        }
        else if (sparkle==3){
            player.texture = SKTexture(imageNamed: "g5.png")
            sparkle = sparkle + 1
        }
        else if (sparkle==4){
            player.texture = SKTexture(imageNamed: "g6.png")
            sparkle = sparkle + 1
        }
        else{
            player.texture = SKTexture(imageNamed: "g7.png")
            sparkle = 1
        }
    }
    
    
    func hurtPlayer(player: SKSpriteNode){
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        if(infMode == false){
            health=health-1
            checkHealth(player)
        }
        
        powerup=powerup-1
        checkPowerup()
        
    }
    
    func checkHealth(player: SKSpriteNode){
        
        //update score label
        if(infMode){
            scoreLabel.text = "Health: ∞\nLevel: \(level)/50\nScore: \(score)"
        }
        else{
            scoreLabel.text = "Health: \(health)\nLevel: \(level)/50\nScore: \(score)"
        }
        
        if (health >= Int(0.66 * Double(maxHealth)) ){
            player.texture = SKTexture(imageNamed: "g3.png")
        }
        else if (health >= Int(0.33 * Double(maxHealth)) ){
            player.texture = SKTexture(imageNamed: "g2.png")
        }
        else if (health > 0){
            player.texture = SKTexture(imageNamed: "g1.png")
        }
        else if(health == 0){
            endGame()
        }
    }
    
    func CollisionWithPlayer(Enemy: BJEnemy,Player:SKSpriteNode){
        
        hurtEnemy(Enemy)
        hurtPlayer(Player)
    }
    
    func CollisionWithPlayerAndBoss(Enemy: BJEnemy,Player:SKSpriteNode){
        
            health=0
            checkHealth(Player)
    }
    
    //*********************************************************************************************
    //*******************************BULLETS*******************************************************
    //*********************************************************************************************
    
    
    func spawnBullets(){
        if(gameStarted==true && gameIsPaused==false){
            //Setup the bullet
            let bullet = SKSpriteNode(imageNamed:bulletTexture)
            
            // put bullet behind the ship
            bullet.zPosition = -5
            //set it to the same position as the ship
            bullet.position = CGPointMake(player.position.x,player.position.y)
            
            //setup physics and collision testing
            bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
            bullet.physicsBody?.categoryBitMask = PhysicsCategory.Bullet
            bullet.physicsBody?.contactTestBitMask = PhysicsCategory.Enemy
            bullet.physicsBody?.affectedByGravity = false
            bullet.physicsBody?.collisionBitMask = 0
            bullet.physicsBody?.dynamic = false
            
            //Move then remove... TODO change speed (duration) based on upgrades.
            let action = SKAction.moveToY(self.size.height + 20, duration: timeToShootBullets)
            let actionDone = SKAction.removeFromParent()
            bullet.runAction(SKAction.sequence([action,actionDone]))
            
            self.addChild(bullet)
        }
    }
    
    func CollisionWithBullet(Enemy: BJEnemy, Bullet: SKSpriteNode){
        
        Bullet.removeFromParent()
        hurtEnemy(Enemy)
        
    }
    
    //*********************************************************************************************
    //*******************************CLOUDS*******************************************************
    //*********************************************************************************************
    
    
    func spawnClouds(){
        
        //Setup the cloud
        let cloud = SKSpriteNode(imageNamed:"c0.png")
        
        // put cloud behind the ship
        
        let randnum = Float(arc4random()) / Float(UINT32_MAX)
        
        if(randnum < 0.5){
            cloud.zPosition = -5
        }
        else{
            cloud.zPosition = 5
        }

        cloud.position = CGPoint(x : CGFloat(arc4random_uniform(UInt32(self.size.width))), y : self.size.height + cloud.size.height)
        cloud.alpha = 0.25
        
        //Move then remove... TODO change speed (duration) based on upgrades.
        let action = SKAction.moveToY(0-cloud.size.height, duration: 8.0)
        let actionDone = SKAction.removeFromParent()
        cloud.runAction(SKAction.sequence([action,actionDone]))
        
        self.addChild(cloud)
    }
    
    
    //*********************************************************************************************
    //*******************************STARS*******************************************************
    //*********************************************************************************************
    
    
    func spawnStars(){
        
        //make the tiny stars happen the most
        
        var starArray = [String]()
        
        for var index = 0; index < 100; ++index{
            starArray.append("s0.png")
            if(index<25){
                starArray.append("s1.png")
            }
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(starArray.count)))
        let starTexture = starArray[randomIndex]
        
        let star = SKSpriteNode(imageNamed: starTexture)
        
        // put cloud behind the ship
        
        let randnum = Float(arc4random()) / Float(UINT32_MAX)
        
        if(randnum < 0.5){
            star.zPosition = -5
        }
        else{
            star.zPosition = 5
        }
        
        star.position = CGPoint(x : CGFloat(arc4random_uniform(UInt32(self.size.width))), y : self.size.height + star.size.height)
        star.alpha = 0.25
        
        //big stars move faster than little stars. it's a fact
        if(starTexture == "s0.png"){
            let action = SKAction.moveToY(0-star.size.height, duration: 3.9)
            let actionDone = SKAction.removeFromParent()
            star.runAction(SKAction.sequence([action,actionDone]))
        }
        else{
            let action = SKAction.moveToY(0-star.size.height, duration: 3.2)
            let actionDone = SKAction.removeFromParent()
            star.runAction(SKAction.sequence([action,actionDone]))
        }
        
        
        self.addChild(star)
    }

    func spawnStarsFast(){
        
        //make the tiny stars happen the most
        
        var starArray = [String]()
        
        for var index = 0; index < 100; ++index{
            starArray.append("s0.png")
            if(index<25){
                starArray.append("s1.png")
            }
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(starArray.count)))
        let starTexture = starArray[randomIndex]
        
        let star = SKSpriteNode(imageNamed: starTexture)
        
        // put cloud behind the ship
        
        let randnum = Float(arc4random()) / Float(UINT32_MAX)
        
        if(randnum < 0.5){
            star.zPosition = -5
        }
        else{
            star.zPosition = 5
        }
        
        star.position = CGPoint(x : CGFloat(arc4random_uniform(UInt32(self.size.width))), y : self.size.height + star.size.height)
        star.alpha = 0.25
        
        //big stars move faster than little stars. it's a fact
        if(starTexture == "s0.png"){
            let action = SKAction.moveToY(0-star.size.height, duration: 0.9)
            let actionDone = SKAction.removeFromParent()
            star.runAction(SKAction.sequence([action,actionDone]))
        }
        else{
            let action = SKAction.moveToY(0-star.size.height, duration: 0.9 )
            let actionDone = SKAction.removeFromParent()
            star.runAction(SKAction.sequence([action,actionDone]))
        }
        
        
        self.addChild(star)
    }
    
    
    //*********************************************************************************************
    //*******************************PHYSICS*******************************************************
    //*********************************************************************************************
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        //These are the "Bodies" that are contacting each other in the world
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if((firstBody.categoryBitMask == PhysicsCategory.Enemy) &&
            (secondBody.categoryBitMask == PhysicsCategory.Bullet)) {
                
                if let firstNode = firstBody.node as? BJEnemy,
                    let secondNode = secondBody.node as? SKSpriteNode {
                        NSLog("DEAD ENEMY")
                        CollisionWithBullet(firstNode, Bullet: secondNode)
                }
        }
        else if((firstBody.categoryBitMask == PhysicsCategory.Boss) &&
            (secondBody.categoryBitMask == PhysicsCategory.Bullet)) {
                
                if let firstNode = firstBody.node as? BJEnemy,
                    let secondNode = secondBody.node as? SKSpriteNode {
                        NSLog("DEAD PLAYER")
                        CollisionWithBullet(firstNode, Bullet: secondNode)
                }
        }
        else if((firstBody.categoryBitMask == PhysicsCategory.Enemy) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                
                if let firstNode = firstBody.node as? BJEnemy,
                    let secondNode = secondBody.node as? SKSpriteNode {
                        NSLog("DEAD PLAYER")
                        CollisionWithPlayer(firstNode, Player: secondNode)
                }
        }
        else if((firstBody.categoryBitMask == PhysicsCategory.Boss) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                
                if let firstNode = firstBody.node as? BJEnemy,
                    let secondNode = secondBody.node as? SKSpriteNode {
                        NSLog("DEAD PLAYER")
                        CollisionWithPlayerAndBoss(firstNode, Player: secondNode)
                }
        }
        else if((firstBody.categoryBitMask == PhysicsCategory.Upgrade) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                
                if let firstNode = firstBody.node as? SKSpriteNode,
                    let secondNode = secondBody.node as? SKSpriteNode {
                        NSLog("UPGRAYEEED")
                        collisionWithHealth(firstNode, player: secondNode)
                }
        }
        else if((firstBody.categoryBitMask == PhysicsCategory.Powerup) &&
            (secondBody.categoryBitMask == PhysicsCategory.Player)) {
                
                if let firstNode = firstBody.node as? SKSpriteNode,
                    let secondNode = secondBody.node as? SKSpriteNode {
                        NSLog("POWERUP")
                        collisionWithPowerup(firstNode, player: secondNode)
                }
        }
        
    }
    
    //*********************************************************************************************
    //*******************************MOVEMENT******************************************************
    //*********************************************************************************************
    
    
    func processUserMotionForUpdate(currentTime: CFTimeInterval) {
        

        if(gameStarted){
            if let data = motionManager.accelerometerData {
                if (player.position.x < (player.size.width) ){
                    player.position.x = player.size.width
                }
                else if ( player.position.x > (self.size.width-player.size.width) ){
                    player.position.x = self.size.width-player.size.width
                }
                else if ( UIDevice.currentDevice().userInterfaceIdiom != UIUserInterfaceIdiom.Pad && fabs(data.acceleration.y) > 0.25) {
                    if(data.acceleration.y < 0 && (player.position.x <= (self.size.width-player.size.width))){
                        player.position.x = player.position.x + 6
                    }
                    else if(data.acceleration.y > 0 && (player.position.x >= (player.size.width)) ){
                        player.position.x = player.position.x - 6

                    }
                }
                else if(padLeft && padRight){
                    //do nothin
                }
                else if(padLeft && (player.position.x >= (player.size.width)) ){
                    //Move the ship to the location of the touch
                    player.position.x = player.position.x - 3
                    //                NSLog("WIDTH \(self.size.width)")
                }
                else if(padRight && (player.position.x <= (self.size.width-player.size.width))){
                    player.position.x = player.position.x + 3
                    //                NSLog("WIDTH \(self.size.width)")
                }
            }
        }
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
        
        for touch in (touches ) {
            
            if (gameStarted == true){
                let location = touch.locationInNode(self)

                if(location.x < CGFloat(self.size.width/2)-10){
                    padLeft = true
                }
                else if (location.x > CGFloat(self.size.width/2)+10){
                    padRight = true
                }

            }
            
            
        }
    }
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch moves */
        
        for touch in (touches ) {
            
            if (gameStarted == true){
                let location = touch.locationInNode(self)
                
                if(location.x < CGFloat(self.size.width/2)-10){
                    padLeft = true
                }
                else if (location.x > CGFloat(self.size.width/2)+10){
                    padRight = true
                }
                else if (location.x >= CGFloat(self.size.width/2)-10 && location.x <= CGFloat(self.size.width/2)+10){
                    padRight = false
                    padLeft = false
                }
                
            }
            
            
        }
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        for touch in (touches ) {
            
            if (gameStarted == true){
                let location = touch.locationInNode(self)
                
                if(location.x < CGFloat(self.size.width/2)-10){
                    padLeft = false
                }
                else if (location.x > CGFloat(self.size.width/2)+10){
                    padRight = false
                }
                else if (location.x >= CGFloat(self.size.width/2)-10 && location.x <= CGFloat(self.size.width/2)+10){
                    padRight = false
                    padLeft = false
                }
                
            }
            
            
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        processUserMotionForUpdate(currentTime)
        

    }
    

    
}
