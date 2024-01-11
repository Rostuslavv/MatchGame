//
//  ViewController.swift
//  MatchTest
//
//  Created by Rostyslav on 09.01.2024.
//

import UIKit

final class MatchViewController: UIViewController {
    
    private enum Constants {
        static let circleSize = 210
        static let buttonFontSize = CGFloat(36)
        static let stepIncreaseCircle = CGFloat(30)
        static let stepDecreaseCircle = CGFloat(30)
        static let maxCollisionCount = 5
        static let animateObstacleDuration = TimeInterval(4)
        static let obstacleWidth = CGFloat(200)
        static let obstacleHeight = CGFloat(10)
        static let backgroundImage = UIImage(named: "Ukraine")!
        static let circleImage = "Kyiv"
    }
    
    private var circleView: UIView!
    private var obstacles: [UIView] = []
    private var obstaclesTimer: Timer!
    private var collisionCount = 0
    private var feedbackGenerator: UINotificationFeedbackGenerator?
    private var animator: UIDynamicAnimator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.contents = Constants.backgroundImage.cgImage
        
        startFuncrion()
    }
    
    private func setupCircle() {
        let circleSize = CGSize(width: Constants.circleSize, height: Constants.circleSize)
        let circleFrame = CGRect(
            x: view.center.x - circleSize.width/2,
            y: view.center.y - circleSize.height/2,
            width: circleSize.width,
            height: circleSize.height)
        
        circleView = UIView(frame: circleFrame)
        circleView.backgroundColor = UIColor(patternImage: UIImage(named: Constants.circleImage)!)
        circleView.layer.cornerRadius = circleView.layer.bounds.width / 2
        
        animator = UIDynamicAnimator(referenceView: view)
        
        view.addSubview(circleView)
    }
    
    private func rotateCircle() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2.0)
        rotationAnimation.duration = 5.0
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        circleView.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
    
    private func setupButtons() {
        let increaseButton = UIButton(type: .system)
        increaseButton.setTitle("+", for: .normal)
        increaseButton.tintColor = .black
        increaseButton.titleLabel?.font = increaseButton.titleLabel?.font.withSize(Constants.buttonFontSize)
        increaseButton.frame = CGRect(
            x: (view.bounds.width / 2) + 15,
            y: view.bounds.height - 60,
            width: 40,
            height: 40)
        
        increaseButton.addTarget(
            self,
            action: #selector(increaseCircleSize),
            for: .touchUpInside)
        
        view.addSubview(increaseButton)
        
        let decreaseButton = UIButton(type: .system)
        decreaseButton.setTitle("-", for: .normal)
        decreaseButton.tintColor = .black
        decreaseButton.titleLabel?.font = decreaseButton.titleLabel?.font.withSize(Constants.buttonFontSize)
        decreaseButton.frame = CGRect(
            x: (view.bounds.width / 2) - 40,
            y: view.bounds.height - 60,
            width: 40,
            height: 40)
        
        decreaseButton.addTarget(
            self,
            action: #selector(decreaseCircleSize),
            for: .touchUpInside)
        
        view.addSubview(decreaseButton)
    }
    
    @objc func increaseCircleSize() {
        let newSize = CGSize(
            width: circleView.frame.width + Constants.stepIncreaseCircle,
            height: circleView.frame.height + Constants.stepIncreaseCircle)
        
        if newSize.width >= 390 {
            updateCircleSize(newSize: CGSize(width: 390, height: 390))
        } else {
            updateCircleSize(newSize: newSize)
        }
    }
    
    @objc func decreaseCircleSize() {
        let newSize = CGSize(
            width: circleView.frame.width - Constants.stepDecreaseCircle,
            height: circleView.frame.height - Constants.stepDecreaseCircle)
        
        if newSize.width < 100 {
            updateCircleSize(newSize: CGSize(width: 120, height: 120))
        } else {
            updateCircleSize(newSize: newSize)
        }
    }
    
    private func updateCircleSize(newSize: CGSize) {
        let maxSize = view.bounds.width
        let newX = view.center.x - newSize.width/2
        let newY = view.center.y - newSize.height/2
        let clampedSize = CGSize(
            width: min(newSize.width, maxSize),
            height: min(newSize.height, maxSize))
        
        circleView.frame = CGRect(
            x: newX,
            y: newY,
            width: clampedSize.width,
            height: clampedSize.height)
        
        circleView.layer.cornerRadius = circleView.layer.bounds.width / 2
    }
    
    private func startObstacles() {
        obstaclesTimer = Timer.scheduledTimer(
            timeInterval: 2,
            target: self,
            selector: #selector(createObstacle),
            userInfo: nil, repeats: true)
    }
    
    @objc func createObstacle() {
        let obstacleWidth = Constants.obstacleWidth
        let obstacleHeight = Constants.obstacleHeight
        let gradientLayer = CAGradientLayer()
        let obstacleView = UIView(frame: CGRect(
            x: view.bounds.width,
            y: CGFloat.random(in: 75...view.bounds.height - 75),
            width: obstacleWidth,
            height: obstacleHeight))
        
        gradientLayer.frame = obstacleView.bounds
        gradientLayer.colors = [UIColor.blue.cgColor, UIColor.yellow.cgColor]
        obstacleView.layer.addSublayer(gradientLayer)
        
        view.addSubview(obstacleView)
        obstacles.append(obstacleView)
        animateObstacle(obstacleView)
    }
    
    private func animateObstacle(_ obstacle: UIView) {
        let animator = UIViewPropertyAnimator(duration: Constants.animateObstacleDuration, curve: .linear) {
            obstacle.frame.origin.x -= self.view.bounds.width + obstacle.frame.width
        }
        
        animator.addCompletion { _ in
            obstacle.removeFromSuperview()
            if let index = self.obstacles.firstIndex(of: obstacle) {
                self.obstacles.remove(at: index)
            }
        }
        
        animator.startAnimation()
        
        if self.checkCollision(circleView: self.circleView, obstacle: obstacle) {
            self.handleCollision()
        }
    }
    
    private func checkCollision(circleView: UIView, obstacle: UIView) -> Bool {
        let circleCenter = CGPoint(x: circleView.frame.midX, y: circleView.frame.midY)
        let dx = circleCenter.x - max(obstacle.frame.minX, min(circleCenter.x, obstacle.frame.maxX))
        let dy = circleCenter.y - max(obstacle.frame.minY, min(circleCenter.y, obstacle.frame.maxY))
        let distance = sqrt(dx * dx + dy * dy)

        return distance < circleView.frame.width / 2  + obstacle.frame.width / 1.4
    }
    
    private func handleCollision() {
        collisionCount += 1
        
        feedbackGenerator?.notificationOccurred(.error)
        
        if collisionCount >= Constants.maxCollisionCount {
            showRestartAlert()
        }
    }
    
    private func showRestartAlert() {
        let alert = UIAlertController(title: "Попередження", message: "Ви маєте перезапустити гру.", preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Перезапустити", style: .default) { _ in
            self.resetGame()
        }
        
        alert.addAction(restartAction)
        present(alert, animated: false, completion: nil)
    }
    
    private func resetGame() {
        obstaclesTimer.invalidate()
        obstacles.removeAll()
        obstacles.forEach { $0.removeFromSuperview() }
        collisionCount = 0
        startObstacles()
    }
    
    private func startFuncrion() {
        setupCircle()
        rotateCircle()
        setupButtons()
        startObstacles()
        feedbackNotification()
    }
    
    private func feedbackNotification() {
        feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator?.prepare()
    }
}
