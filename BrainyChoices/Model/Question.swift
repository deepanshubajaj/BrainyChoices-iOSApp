//
//  Question.swift
//  BrainyChoices
//
//  Created by Deepanshu Bajaj on 05/12/24.
//

import Foundation

struct Question {
    let text: String
    let answers: [String]
    let rightAnswer: String
    
    init(q: String, a: [String], correctAnswer: String) {
        text = q
        answers = a
        rightAnswer = correctAnswer
    }
}
