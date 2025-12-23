//
//  QuestionBanks.swift
//  thelongevityapp
//
//  Created on 17.12.2025.
//

import Foundation

struct QuestionBanks {
    static let onboardingQuestions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: "sleep",
            prompt: "How would you rate your typical sleep quality and duration?",
            options: [
                OptionItem(title: "Very poor (<5 hours, restless)", value: .minus1),
                OptionItem(title: "Below average (5-6 hours, interrupted)", value: .minusHalf),
                OptionItem(title: "Neutral (6-7 hours, occasional issues)", value: .zero),
                OptionItem(title: "Good (7-8 hours, mostly restful)", value: .plusHalf),
                OptionItem(title: "Excellent (8+ hours, consistently deep)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "activity",
            prompt: "How active is your daily routine?",
            options: [
                OptionItem(title: "Very sedentary (mostly sitting)", value: .minus1),
                OptionItem(title: "Light activity (walking <30 min/day)", value: .minusHalf),
                OptionItem(title: "Moderate (30-60 min movement/day)", value: .zero),
                OptionItem(title: "Active (60+ min exercise/week)", value: .plusHalf),
                OptionItem(title: "Very active (150+ min/week, strength training)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "muscle",
            prompt: "How would you assess your muscle mass and strength?",
            options: [
                OptionItem(title: "Very low (noticeable weakness)", value: .minus1),
                OptionItem(title: "Below average (struggles with daily tasks)", value: .minusHalf),
                OptionItem(title: "Average (maintains basic strength)", value: .zero),
                OptionItem(title: "Good (regular strength training)", value: .plusHalf),
                OptionItem(title: "Excellent (high muscle mass, strong)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "visceralFat",
            prompt: "How would you describe your body composition, especially around the midsection?",
            options: [
                OptionItem(title: "High visceral fat (significant belly fat)", value: .minus1),
                OptionItem(title: "Above average (some excess abdominal fat)", value: .minusHalf),
                OptionItem(title: "Average (moderate body fat)", value: .zero),
                OptionItem(title: "Good (low body fat, toned)", value: .plusHalf),
                OptionItem(title: "Excellent (lean, defined abs)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "nutritionPattern",
            prompt: "How would you rate your overall nutrition pattern?",
            options: [
                OptionItem(title: "Very poor (mostly processed, fast food)", value: .minus1),
                OptionItem(title: "Below average (inconsistent, some processed)", value: .minusHalf),
                OptionItem(title: "Neutral (mixed, some whole foods)", value: .zero),
                OptionItem(title: "Good (mostly whole foods, balanced)", value: .plusHalf),
                OptionItem(title: "Excellent (whole foods, nutrient-dense, planned)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "sugar",
            prompt: "How much added sugar and refined carbs do you consume?",
            options: [
                OptionItem(title: "Very high (daily sweets, sodas, desserts)", value: .minus1),
                OptionItem(title: "High (several times/week)", value: .minusHalf),
                OptionItem(title: "Moderate (occasional treats)", value: .zero),
                OptionItem(title: "Low (rarely, mostly natural sources)", value: .plusHalf),
                OptionItem(title: "Minimal (almost none, whole foods only)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "stress",
            prompt: "How would you rate your stress levels and management?",
            options: [
                OptionItem(title: "Very high (chronic stress, overwhelmed)", value: .minus1),
                OptionItem(title: "High (frequent stress, limited coping)", value: .minusHalf),
                OptionItem(title: "Moderate (some stress, occasional management)", value: .zero),
                OptionItem(title: "Low (good coping strategies)", value: .plusHalf),
                OptionItem(title: "Very low (excellent stress management, calm)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "smokingAlcohol",
            prompt: "Do you smoke or consume alcohol regularly?",
            options: [
                OptionItem(title: "Heavy (daily smoking or heavy drinking)", value: .minus1),
                OptionItem(title: "Regular (smoking or drinking several times/week)", value: .minusHalf),
                OptionItem(title: "Occasional (social drinking, no smoking)", value: .zero),
                OptionItem(title: "Rare (very occasional, minimal)", value: .plusHalf),
                OptionItem(title: "None (no smoking, no alcohol)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "metabolicHealth",
            prompt: "How would you assess your metabolic health (energy, blood sugar stability)?",
            options: [
                OptionItem(title: "Poor (energy crashes, sugar cravings)", value: .minus1),
                OptionItem(title: "Below average (occasional crashes)", value: .minusHalf),
                OptionItem(title: "Average (stable most of the time)", value: .zero),
                OptionItem(title: "Good (consistent energy, stable)", value: .plusHalf),
                OptionItem(title: "Excellent (high energy, no crashes)", value: .plus1)
            ]
        ),
        OnboardingQuestion(
            id: "energyFocus",
            prompt: "How would you rate your daily energy and mental focus?",
            options: [
                OptionItem(title: "Very low (constant fatigue, brain fog)", value: .minus1),
                OptionItem(title: "Low (frequent tiredness, poor focus)", value: .minusHalf),
                OptionItem(title: "Average (moderate energy, decent focus)", value: .zero),
                OptionItem(title: "Good (consistent energy, good focus)", value: .plusHalf),
                OptionItem(title: "Excellent (high energy, sharp focus)", value: .plus1)
            ]
        )
    ]
    
    static let dailyQuestions: [DailyQuestion] = [
        DailyQuestion(
            id: "sleep",
            prompt: "How was your sleep last night?",
            options: [
                OptionItem(title: "Very poor (<5 hours, restless)", value: .minus1),
                OptionItem(title: "Below average (5-6 hours, interrupted)", value: .minusHalf),
                OptionItem(title: "Neutral (6-7 hours, okay)", value: .zero),
                OptionItem(title: "Good (7-8 hours, restful)", value: .plusHalf),
                OptionItem(title: "Excellent (8+ hours, deep sleep)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "movement",
            prompt: "How much movement did you get today?",
            options: [
                OptionItem(title: "Very sedentary (almost no movement)", value: .minus1),
                OptionItem(title: "Light (walking <30 min)", value: .minusHalf),
                OptionItem(title: "Moderate (30-60 min activity)", value: .zero),
                OptionItem(title: "Active (60+ min exercise)", value: .plusHalf),
                OptionItem(title: "Very active (intense workout + movement)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "foodQuality",
            prompt: "How would you rate today's food quality?",
            options: [
                OptionItem(title: "Very poor (mostly processed, fast food)", value: .minus1),
                OptionItem(title: "Below average (some processed foods)", value: .minusHalf),
                OptionItem(title: "Neutral (mixed, some whole foods)", value: .zero),
                OptionItem(title: "Good (mostly whole foods, balanced)", value: .plusHalf),
                OptionItem(title: "Excellent (nutrient-dense, whole foods)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "sugar",
            prompt: "How much added sugar did you consume today?",
            options: [
                OptionItem(title: "Very high (multiple sweets, sodas)", value: .minus1),
                OptionItem(title: "High (desserts, sweet drinks)", value: .minusHalf),
                OptionItem(title: "Moderate (some treats)", value: .zero),
                OptionItem(title: "Low (minimal, natural sources)", value: .plusHalf),
                OptionItem(title: "Minimal (almost none)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "stress",
            prompt: "How stressed did you feel today?",
            options: [
                OptionItem(title: "Very high (overwhelmed, anxious)", value: .minus1),
                OptionItem(title: "High (frequent stress)", value: .minusHalf),
                OptionItem(title: "Moderate (some stress)", value: .zero),
                OptionItem(title: "Low (managed well)", value: .plusHalf),
                OptionItem(title: "Very low (calm, relaxed)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "mentalLoad",
            prompt: "How would you rate your mental workload today?",
            options: [
                OptionItem(title: "Very high (overwhelming, exhausted)", value: .minus1),
                OptionItem(title: "High (heavy cognitive load)", value: .minusHalf),
                OptionItem(title: "Moderate (manageable)", value: .zero),
                OptionItem(title: "Low (balanced, manageable)", value: .plusHalf),
                OptionItem(title: "Very low (light, relaxed)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "moodSocial",
            prompt: "How was your mood and social connection today?",
            options: [
                OptionItem(title: "Very poor (isolated, negative mood)", value: .minus1),
                OptionItem(title: "Below average (low mood, limited connection)", value: .minusHalf),
                OptionItem(title: "Neutral (okay mood, some connection)", value: .zero),
                OptionItem(title: "Good (positive mood, good connections)", value: .plusHalf),
                OptionItem(title: "Excellent (great mood, strong connections)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "bodyFeel",
            prompt: "How does your body feel today?",
            options: [
                OptionItem(title: "Very poor (aches, pains, discomfort)", value: .minus1),
                OptionItem(title: "Below average (some discomfort)", value: .minusHalf),
                OptionItem(title: "Neutral (normal, no issues)", value: .zero),
                OptionItem(title: "Good (comfortable, energetic)", value: .plusHalf),
                OptionItem(title: "Excellent (strong, vibrant, pain-free)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "inflammationSignal",
            prompt: "Any signs of inflammation or recovery issues?",
            options: [
                OptionItem(title: "High (swelling, pain, slow recovery)", value: .minus1),
                OptionItem(title: "Moderate (some inflammation signs)", value: .minusHalf),
                OptionItem(title: "Neutral (no obvious signs)", value: .zero),
                OptionItem(title: "Low (minimal, recovering well)", value: .plusHalf),
                OptionItem(title: "None (no inflammation, optimal recovery)", value: .plus1)
            ]
        ),
        DailyQuestion(
            id: "selfCare",
            prompt: "How well did you practice self-care today?",
            options: [
                OptionItem(title: "Very poor (neglected, no self-care)", value: .minus1),
                OptionItem(title: "Below average (minimal self-care)", value: .minusHalf),
                OptionItem(title: "Neutral (some self-care)", value: .zero),
                OptionItem(title: "Good (regular self-care practices)", value: .plusHalf),
                OptionItem(title: "Excellent (comprehensive self-care routine)", value: .plus1)
            ]
        )
    ]
}
