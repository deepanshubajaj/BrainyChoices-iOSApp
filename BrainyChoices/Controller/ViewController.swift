//
//  ViewController.swift
//  BrainyChoices
//
//  Created by Deepanshu Bajaj on 05/12/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var choice1: UIButton!
    @IBOutlet weak var choice2: UIButton!
    @IBOutlet weak var choice3: UIButton!
    
    var quizBrain = QuizBrain()
    var player: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe when app moves to the background
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Observe when app returns to the foreground
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        updateUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showWelcomeAlert()
    }
    
    @objc func appMovedToBackground() {
        player?.pause()  // Pause the sound when app goes to the background
    }
    
    @objc func appMovedToForeground() {
        if let player = player, !player.isPlaying {
            player.play()  // Resume the sound when app comes to the foreground
        }
    }
    
    @IBAction func answerButtonPressed(_ sender: UIButton) {
        let userAnswer = sender.currentTitle! // True, False
        let userGotItRight = quizBrain.checkAnswer(userAnswer)
        
        if userGotItRight {
            sender.backgroundColor = UIColor.green
            playSound(soundName: "correctAudio", soundFileExtension: "mp3" )
        } else {
            sender.backgroundColor = UIColor.red
            playSound(soundName: "wrongAudio", soundFileExtension: "mp3" )
        }
        
        // Check if the user has answered the last question
        if quizBrain.questionNumber + 1 == quizBrain.quiz.count {
            
            scoreLabel.text = "Final Score: \(quizBrain.getScore()) / \(quizBrain.quiz.count) (\(quizBrain.getPercentage())%)"
            
            // Delay a little bit to show the color feedback before showing the alert
            Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(showFinalAlert), userInfo: nil, repeats: false)
            
        } else {
            
            quizBrain.nextQuestion()
            
            Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(updateUI), userInfo: nil, repeats: false)
            
        }
    }
    
    @objc func updateUI() {
        questionLabel.text = quizBrain.getQuestionText()
        
        let answerChoices = quizBrain.getAnswers()
        choice1.setTitle(answerChoices[0], for: .normal)
        choice2.setTitle(answerChoices[1], for: .normal)
        choice3.setTitle(answerChoices[2], for: .normal)
        
        progressBar.progress = quizBrain.getProgress()
        scoreLabel.text = "Score: \(quizBrain.getScore()) / \(quizBrain.quiz.count) (\(quizBrain.getPercentage())%)"
        
        choice1.backgroundColor = UIColor.clear
        choice2.backgroundColor = UIColor.clear
        choice3.backgroundColor = UIColor.clear
    }
    
    func playSound(soundName: String, soundFileExtension: String, loop: Bool = false) {
        let url = Bundle.main.url(forResource: soundName, withExtension: soundFileExtension)
        do {
            player = try AVAudioPlayer(contentsOf: url!)
            
            if loop {
                player?.numberOfLoops = -1
            } else {
                player?.numberOfLoops = 0
            }
            
            player?.play()
        } catch {
            print("Error initializing audio player: \(error)")
        }
    }
    
    func stopSound() {
        player?.stop()
        player = nil
    }
    
    func showWelcomeAlert() {
        playSound(soundName: "rulesAudio", soundFileExtension: "mp3", loop: true )
        let welcomeAlert = UIAlertController(title: "Welcome to BrainBricks", message: nil, preferredStyle: .alert)
        
        // Creation of justified paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .justified
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Create an attributed string with the justified paragraph style
        let messageText = """
        Instructions to be followed:
        1) Please select anyone of the options given.
        2) Scores will be displayed at the end.
        3) For Win, score 80% or above.
        4) Please click "Enter" to begin.
        """
        
        let attributedMessage = NSAttributedString(
            string: messageText,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)
            ]
        )
        
        // Set the attributed message for the alert
        welcomeAlert.setValue(attributedMessage, forKey: "attributedMessage")
        
        let enterAction = UIAlertAction(title: "Enter", style: .default) { _ in
            // Welcome Alert Dismiss
            self.stopSound()
        }
        
        welcomeAlert.addAction(enterAction)
        present(welcomeAlert, animated: true, completion: nil)
    }
    
    
    // Function to show the first alert depending on the score
    @objc func showFinalAlert() {
        
        let scorePercentage = quizBrain.getPercentage()
        
        // Check for percentage to be 80% in order to win
        if scorePercentage >= 80 {
            
            playSound(soundName: "winnerAudio", soundFileExtension: "mp3")
            let message = """
                Your final score is \(quizBrain.getScore()) / \(quizBrain.quiz.count) ,
                which is approx. \(Int(scorePercentage))%.
                So, Congratulations you Passed!
                """
            
            let winnerAlert = UIAlertController(
                title: "Winner Winner Chicken Dinner!",
                message: message,
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(title: "Next>>>", style: .default) { _ in
                self.showFinalScoreAlert() // Show the final score alert after "OK" is pressed
            }
            
            winnerAlert.addAction(okAction)
            present(winnerAlert, animated: true, completion: nil)
        } else {
            
            playSound(soundName: "failAudio", soundFileExtension: "mp3")
            let failureAlert = UIAlertController(title: "Sorry! You Failed!", message: "You scored \(scorePercentage)% (< 80%).", preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Next>>>", style: .default) { _ in
                self.showFinalScoreAlert() // Show the final score alert after "OK" is pressed
            }
            
            failureAlert.addAction(okAction)
            present(failureAlert, animated: true, completion: nil)
        }
    }
    
    // Function to show the final score alert
    func showFinalScoreAlert() {
        
        let passMessage = """
                          Kudos! You have completed the quiz by WINNING it 👍.
                          What you want next?
                          """
        let failMessage = """
                          Sorry! You have completed the quiz by LOOSING it 👎.
                          What you want next?
                          """
        let finalMessage = quizBrain.getPercentage() >= 80 ? passMessage : failMessage
        
        let finalAlert = UIAlertController(
            title: "Quiz Completed!",
            message: finalMessage,
            preferredStyle: .alert
        )
        
        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default) { _ in
            self.resetQuiz()
            self.showWelcomeAlert()
        }
        
        let nextTimeAction = UIAlertAction(title: "Next Time", style: .default) { _ in
            self.showCloseAppAlert()
        }
        
        finalAlert.addAction(tryAgainAction)
        finalAlert.addAction(nextTimeAction)
        
        present(finalAlert, animated: true, completion: nil)
    }
    
    func showCloseAppAlert() {
        playSound(soundName: "dangerAudio", soundFileExtension: "mp3", loop: true)
        let closeAppAlert = UIAlertController(
            title: "ALERT ⚠️",
            message: "Application is Terminated.\nPlease close the application manually.",
            preferredStyle: .alert
        )
        
        let subview = closeAppAlert.view.subviews.first?.subviews.first?.subviews.first
        subview?.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)  // Light red color

        present(closeAppAlert, animated: true, completion: nil)
    }
    
    // Function to reset the quiz
    func resetQuiz() {
        quizBrain.questionNumber = 0
        quizBrain.score = 0
        updateUI()
    }
}


