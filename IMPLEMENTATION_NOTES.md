# Implementation Notes

## Setting Up the Project in Xcode

### 1. Create New Xcode Project
1. Open Xcode and select "Create a new Xcode project"
2. Choose "App" under iOS
3. Configure:
   - Product Name: `HealthOptimizer`
   - Team: Your development team
   - Organization Identifier: Your identifier (e.g., `com.yourcompany`)
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
   - Uncheck "Include Tests" (add later)

### 2. Project Configuration
1. Set minimum deployment target to iOS 17.0
2. Enable "Automatically manage signing"
3. Add capability "Keychain Sharing" if needed for API key storage

### 3. Add Dependencies

Add these Swift Package Manager dependencies:

#### OpenAI (MacPaw)
- URL: `https://github.com/MacPaw/OpenAI.git`
- Version: Up to Next Major Version

#### Firebase iOS SDK
- URL: `https://github.com/firebase/firebase-ios-sdk.git`
- Version: Up to Next Major Version
- Products needed: `FirebaseAI`, `FirebaseCore`

### 4. Add Source Files
Copy all `.swift` files maintaining folder structure:
- App/
- Models/
- Services/
- ViewModels/
- Views/
- Utilities/

## AI Provider Configuration

### Supported Providers

HealthOptimizer supports three AI providers:

1. **Claude (Anthropic)** - Excellent for nuanced health analysis
2. **GPT (OpenAI)** - Powerful general-purpose AI  
3. **Gemini (Google)** - Integrated via Firebase AI Logic

### Claude (Anthropic) Setup
1. Go to [console.anthropic.com](https://console.anthropic.com)
2. Create an account or sign in
3. Navigate to API Keys section
4. Generate a new API key
5. In the app: Settings > Claude API Key > Enter key

### OpenAI GPT Setup
1. Go to [platform.openai.com](https://platform.openai.com)
2. Create an account or sign in
3. Navigate to API Keys
4. Generate a new API key
5. In the app: Settings > OpenAI API Key > Enter key

### Gemini (Firebase) Setup
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project or select existing
3. Enable the Gemini API in your project
4. Download `GoogleService-Info.plist`
5. Add `GoogleService-Info.plist` to your Xcode project root
6. The app will automatically detect Firebase configuration

**Important**: API keys are stored securely in the iOS Keychain.

## Available Models

### Claude Models
- `claude-sonnet-4-20250514` (default)
- `claude-3-5-sonnet-20241022`
- `claude-3-haiku-20240307`

### OpenAI Models
- `gpt-4o` (default)
- `gpt-4o-mini`
- `gpt-4-turbo`
- `gpt-3.5-turbo`

### Gemini Models
- `gemini-2.0-flash` (default)
- `gemini-1.5-flash`
- `gemini-1.5-pro`

## Testing Recommendations

### Unit Testing
Create tests for:
- Model validation (UserProfile, HealthCondition enums)
- BMI/BMR/TDEE calculations
- ViewModel state management
- Keychain operations (use mock)
- API response parsing

### UI Testing
- Onboarding flow completion
- Tab navigation
- Sheet presentations
- Form validation feedback

### Testing Without API
Use the `MockAIService` class for testing without API calls:
```swift
let viewModel = DashboardViewModel(
    aiService: MockAIService(),
    persistenceService: .shared
)
```

### Sample Data
Sample data is provided for previews:
- `UserProfile.sampleProfile`
- `HealthRecommendation.sample`
- `SupplementPlan.sample`
- `WorkoutPlan.sample`
- `DietPlan.sample`

## Cost Estimates

### Claude
- ~4,000-8,000 tokens per generation
- ~$0.03-0.06 per recommendation (Sonnet pricing)

### OpenAI
- ~4,000-8,000 tokens per generation
- ~$0.03-0.10 per recommendation (GPT-4o pricing)

### Gemini
- Uses Firebase billing
- Free tier available with limits
- See Firebase pricing for details

## Future Enhancement Suggestions

### Phase 1: Core Improvements
1. **HealthKit Integration**
   - Import health data (weight, height, activity)
   - Sync workout data
   - Track sleep automatically

2. **Progress Tracking**
   - Weight logging with charts
   - Workout completion tracking
   - Supplement adherence tracking
   - Photo progress

3. **Notifications**
   - Supplement reminders
   - Workout reminders
   - Meal timing reminders
   - Weekly check-in prompts

### Phase 2: Advanced Features
1. **Workout Timer**
   - Built-in workout timer
   - Rest period countdown
   - Exercise tracking during workout

2. **Meal Planning**
   - Grocery list generation
   - Recipe saving/favoriting
   - Nutritional tracking
   - Barcode scanning

3. **AI Improvements**
   - Chat with AI for questions
   - Regenerate specific sections
   - Adjust recommendations based on progress
   - Voice input for logging
   - Provider comparison feature

### Phase 3: Social & Premium
1. **Social Features**
   - Share progress
   - Community challenges
   - Trainer marketplace

2. **Premium Features**
   - Multiple AI regenerations
   - Video exercise guides
   - Detailed blood work analysis
   - Personalized supplement sourcing

## Security Considerations

### HIPAA Awareness
While this app is designed with HIPAA principles in mind:
- All data stored locally on device
- No cloud sync of health data
- Anonymized AI requests
- User control over data export/deletion

**Note**: This app is not HIPAA-certified and should not be used for medical diagnosis or treatment.

### Data Protection
- API keys stored in Keychain (not UserDefaults)
- Health data in encrypted SwiftData store
- No third-party analytics (add only with user consent)
- Clear privacy disclosures

### Best Practices
1. Never log sensitive health data
2. Implement biometric lock option
3. Auto-lock after inactivity
4. Secure data export (encrypted if sharing)

## Troubleshooting

### Common Issues

**"Claude API key not working"**
- Ensure key starts with `sk-ant-`
- Check for extra whitespace
- Verify account has credits

**"OpenAI API key not working"**
- Ensure key starts with `sk-`
- Check for extra whitespace
- Verify account has credits and correct permissions

**"Gemini not available"**
- Ensure `GoogleService-Info.plist` is in project root
- Verify Firebase project has Gemini API enabled
- Check Firebase console for quota/billing issues

**"Recommendations not generating"**
- Check internet connection
- Verify selected provider is configured
- Check console for detailed error
- Try switching to a different provider

**"Data not persisting"**
- Ensure SwiftData container is properly configured
- Check for modelContext save errors
- Verify model schema matches

## Code Style Guidelines

1. **MARK comments** for code organization
2. **Documentation comments** for public interfaces
3. **Preview providers** for all views
4. **Dependency injection** for testability
5. **Protocol-oriented** design for flexibility

## Release Checklist

- [ ] Remove all debug prints
- [ ] Test on multiple device sizes
- [ ] Test with VoiceOver
- [ ] Verify all AI providers work
- [ ] Check memory leaks
- [ ] Update version number
- [ ] Prepare App Store screenshots
- [ ] Write App Store description
- [ ] Configure App Privacy details
- [ ] Submit for review
