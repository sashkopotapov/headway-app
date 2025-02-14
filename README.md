# Headway Take-Home Task

This is a take-home task for **Headway**—a simple audiobook player built with modern Swift and TCA, focusing on user experience rather than overcomplicating functionality.

## Project Basics

- **Swift:** 6
- **iOS:** 18.0
- **TCA:** 1.17.1

## Book & Data Sources

- **Book:** *The Happy Prince and Other Tales* by Oscar Wilde
- **Text Source:** [Project Gutenberg](https://www.gutenberg.org/ebooks/902)
- **Chapter Summaries & Key Points:** Generated using ChatGPT-4
- **Audio Creation:** [11Labs](https://elevenlabs.io/)

> **Note:** Since audio content is curated (users can’t upload anything), I prepared a JSON file with the book text and corresponding audio files. This simplified a lot of work.

## Design Decisions

- **Simplicity & UX:**  
  I focused on delivering a great user experience without overengineering the solution. The app consists of a single Feature (Reducer) because users care about how it works, not about the underlying code.
  
- **Audio Playback:**  
  I used `AVAudioPlayer` to track progress via regular fetching of `.currentTime` instead of using `AVPlayer`. Although `AVPlayer` offers dedicated playback tracking (as recommended by [Apple](https://developer.apple.com/documentation/avfoundation/monitoring-playback-progress-in-your-app)), its API is somewhat outdated and less compatible with modern Swift concurrency. In production, I’d dive deeper, test, profile, and compare approaches—possibly using `AVAudioPlayer`’s delegate method `audioPlayerDidFinishPlaying(_:successfully:)` for a more reliable finish detection.

## UX Notes

- **Slider Behavior:**  
  I'm not a huge fan of instantly reactive sliders—I'd rather apply changes once the user finishes interacting. However, this approach mimics the Headway original app (you might notice the slider slightly jumps in the original app).
  
- **Chapter Navigation:**  
  The next chapter is opened automatically when the audio finishes. If it’s the last chapter, playback loops back to the first chapter.

## Possible Improvements

- **Text View:** Adding a text view for displaying the book's content is a low-hanging fruit.
- **AVPlayer Exploration:** Further exploration of `AVPlayer` might reveal benefits in terms of playback handling.
- **Adaptive Progress Interval:** Adjust the progress notification interval (e.g., 1 second divided by the current playback speed) when the playback speed changes.
- **Reliable Chapter-End Detection:** Instead of using progress/tolerance-based checks, leveraging `AVAudioPlayer`’s `audioPlayerDidFinishPlaying(_:successfully:)` could provide a more robust solution for detecting chapter completion.
- **Improved Slider Interaction:** Consider pausing slider binding while the user is interacting with it and sending the final value once the interaction is finished. This approach could lead to smoother, more deliberate control.

---

Thanks for checking out this project!
