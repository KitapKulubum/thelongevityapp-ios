//
//  QuestionBanks.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation

@MainActor
class QuestionBanks {
    static let shared = QuestionBanks()
    
    private let languageManager = LanguageManager.shared
    
    private init() {}
    
    var onboardingQuestions: [OnboardingQuestion] {
        [
        OnboardingQuestion(
            id: "sleep",
            prompt: languageManager.localized("How would you rate your typical sleep quality and duration?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (<5 hours, restless)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (5-6 hours, interrupted)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (6-7 hours, occasional issues)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (7-8 hours, mostly restful)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (8+ hours, consistently deep)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "activity",
            prompt: languageManager.localized("How active is your daily routine?"),
            options: [
                OptionItem(title: languageManager.localized("Very sedentary (mostly sitting)"), value: .minus1),
                OptionItem(title: languageManager.localized("Light activity (walking <30 min/day)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (30-60 min movement/day)"), value: .zero),
                OptionItem(title: languageManager.localized("Active (60+ min exercise/week)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Very active (150+ min/week, strength training)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "muscle",
            prompt: languageManager.localized("How would you assess your muscle mass and strength?"),
            options: [
                OptionItem(title: languageManager.localized("Very low (noticeable weakness)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (struggles with daily tasks)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Average (maintains basic strength)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (regular strength training)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (high muscle mass, strong)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "visceralFat",
            prompt: languageManager.localized("How would you describe your body composition, especially around the midsection?"),
            options: [
                OptionItem(title: languageManager.localized("High visceral fat (significant belly fat)"), value: .minus1),
                OptionItem(title: languageManager.localized("Above average (some excess abdominal fat)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Average (moderate body fat)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (low body fat, toned)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (lean, defined abs)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "nutritionPattern",
            prompt: languageManager.localized("How would you rate your overall nutrition pattern?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (mostly processed, fast food)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (inconsistent, some processed)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (mixed, some whole foods)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (mostly whole foods, balanced)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (whole foods, nutrient-dense, planned)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "sugar",
            prompt: languageManager.localized("How much added sugar and refined carbs do you consume?"),
            options: [
                OptionItem(title: languageManager.localized("Very high (daily sweets, sodas, desserts)"), value: .minus1),
                OptionItem(title: languageManager.localized("High (several times/week)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (occasional treats)"), value: .zero),
                OptionItem(title: languageManager.localized("Low (rarely, mostly natural sources)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Minimal (almost none, whole foods only)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "stress",
            prompt: languageManager.localized("How would you rate your stress levels and management?"),
            options: [
                OptionItem(title: languageManager.localized("Very high (chronic stress, overwhelmed)"), value: .minus1),
                OptionItem(title: languageManager.localized("High (frequent stress, limited coping)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (some stress, occasional management)"), value: .zero),
                OptionItem(title: languageManager.localized("Low (good coping strategies)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Very low (excellent stress management, calm)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "smokingAlcohol",
            prompt: languageManager.localized("Do you smoke or consume alcohol regularly?"),
            options: [
                OptionItem(title: languageManager.localized("Heavy (daily smoking or heavy drinking)"), value: .minus1),
                OptionItem(title: languageManager.localized("Regular (smoking or drinking several times/week)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Occasional (social drinking, no smoking)"), value: .zero),
                OptionItem(title: languageManager.localized("Rare (very occasional, minimal)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("None (no smoking, no alcohol)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "metabolicHealth",
            prompt: languageManager.localized("How would you assess your metabolic health (energy, blood sugar stability)?"),
            options: [
                OptionItem(title: languageManager.localized("Poor (energy crashes, sugar cravings)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (occasional crashes)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Average (stable most of the time)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (consistent energy, stable)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (high energy, no crashes)"), value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "energyFocus",
            prompt: languageManager.localized("How would you rate your daily energy and mental focus?"),
            options: [
                OptionItem(title: languageManager.localized("Very low (constant fatigue, brain fog)"), value: .minus1),
                OptionItem(title: languageManager.localized("Low (frequent tiredness, poor focus)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Average (moderate energy, decent focus)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (consistent energy, good focus)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (high energy, sharp focus)"), value: .plus1)
            ]
        )
        ]
    }
    
    var dailyQuestions: [DailyQuestion] {
        [
        DailyQuestion(
            id: "sleep",
            prompt: languageManager.localized("How was your sleep last night?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (<5 hours, restless)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (5-6 hours, interrupted)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (6-7 hours, okay)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (7-8 hours, restful)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (8+ hours, deep sleep)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "movement",
            prompt: languageManager.localized("How much movement did you get today?"),
            options: [
                OptionItem(title: languageManager.localized("Very sedentary (almost no movement)"), value: .minus1),
                OptionItem(title: languageManager.localized("Light (walking <30 min)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (30-60 min activity)"), value: .zero),
                OptionItem(title: languageManager.localized("Active (60+ min exercise)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Very active (intense workout + movement)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "foodQuality",
            prompt: languageManager.localized("How would you rate today's food quality?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (mostly processed, fast food)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (some processed foods)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (mixed, some whole foods)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (mostly whole foods, balanced)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (nutrient-dense, whole foods)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "sugar",
            prompt: languageManager.localized("How much added sugar did you consume today?"),
            options: [
                OptionItem(title: languageManager.localized("Very high (multiple sweets, sodas)"), value: .minus1),
                OptionItem(title: languageManager.localized("High (desserts, sweet drinks)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (some treats)"), value: .zero),
                OptionItem(title: languageManager.localized("Low (minimal, natural sources)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Minimal (almost none)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "stress",
            prompt: languageManager.localized("How stressed did you feel today?"),
            options: [
                OptionItem(title: languageManager.localized("Very high (overwhelmed, anxious)"), value: .minus1),
                OptionItem(title: languageManager.localized("High (frequent stress)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (some stress)"), value: .zero),
                OptionItem(title: languageManager.localized("Low (managed well)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Very low (calm, relaxed)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "mentalLoad",
            prompt: languageManager.localized("How would you rate your mental workload today?"),
            options: [
                OptionItem(title: languageManager.localized("Very high (overwhelming, exhausted)"), value: .minus1),
                OptionItem(title: languageManager.localized("High (heavy cognitive load)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Moderate (manageable)"), value: .zero),
                OptionItem(title: languageManager.localized("Low (balanced, manageable)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Very low (light, relaxed)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "moodSocial",
            prompt: languageManager.localized("How was your mood and social connection today?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (isolated, negative mood)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (low mood, limited connection)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (okay mood, some connection)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (positive mood, good connections)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (great mood, strong connections)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "bodyFeel",
            prompt: languageManager.localized("How does your body feel today?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (aches, pains, discomfort)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (some discomfort)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (normal, no issues)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (comfortable, energetic)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (strong, vibrant, pain-free)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "inflammationSignal",
            prompt: languageManager.localized("Any signs of inflammation or recovery issues?"),
            options: [
                OptionItem(title: languageManager.localized("High (swelling, pain, slow recovery)"), value: .minus1),
                OptionItem(title: languageManager.localized("Moderate (some inflammation signs)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (no obvious signs)"), value: .zero),
                OptionItem(title: languageManager.localized("Low (minimal, recovering well)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("None (no inflammation, optimal recovery)"), value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "selfCare",
            prompt: languageManager.localized("How well did you practice self-care today?"),
            options: [
                OptionItem(title: languageManager.localized("Very poor (neglected, no self-care)"), value: .minus1),
                OptionItem(title: languageManager.localized("Below average (minimal self-care)"), value: .minusHalf),
                OptionItem(title: languageManager.localized("Neutral (some self-care)"), value: .zero),
                OptionItem(title: languageManager.localized("Good (regular self-care practices)"), value: .plusHalf),
                OptionItem(title: languageManager.localized("Excellent (comprehensive self-care routine)"), value: .plus1)
            ]
        )
        ]
    }
}
