🧠 MindMentor

MindMentor is a Salesforce-powered mental wellness application designed to help users develop self-awareness and healthy emotional habits through guided AI interaction, mood tracking, and journaling.

🌟 Overview

MindMentor offers a safe and personalized space for users to explore their mental wellness journey. Built on Salesforce Experience Cloud and Agentforce AI, it blends structured self-assessments with intelligent, empathetic conversations — without collecting or storing medical data.

⸻

🚀 Features
	•	Mood Tracking
Log daily moods, add notes, and observe emotional patterns over time.
	•	Journaling
Maintain a private reflective journal with prompts from the AI assistant.
	•	Reminders
Set personalized reminders for wellness check-ins or journaling.
	•	Onboarding Questionnaire
A guided assessment to understand the user’s current emotional state and tailor recommendations.
	•	AI Therapist Chat (Powered by Agentforce)
An AI-driven companion that engages in supportive conversations and suggests mindfulness activities.
	•	Admin Dashboard (Salesforce)
Manage users, sessions, and content configurations within Salesforce.

⸻

🧩 Architecture
	•	Platform: Salesforce Experience Cloud (LWR site)
	•	Backend: Apex (custom controllers for questionnaire, session tracking, etc.)
	•	Frontend: Lightning Web Components (LWCs)
	•	AI Integration: Agentforce (Salesforce AI platform)
	•	Data Model: Custom Salesforce objects for Mood Entries, Journal Entries, Reminders, Onboarding Responses, and Chat Sessions

⸻

🔒 Data & Privacy
	•	Focuses exclusively on behavioral and wellness data — no clinical or medical information is stored.
	•	User data is protected through Salesforce’s standard security and sharing model.

⸻

🧱 Future Enhancements
	•	Introduce human therapist integrations
	•	Add progress analytics and goal-setting
	•	Enable mobile-friendly push notifications
	•	Expand personalization based on AI insights

⸻

🧑‍💻 Setup Instructions
	1.	Clone this repository

git clone https://github.com/Abhinavgithub/MindMentor.git


	2.	Deploy to Salesforce DX or Developer Org

sfdx force:source:deploy -p force-app


	3.	Configure the Experience Cloud site and assign profiles.
	4.	Enable Agentforce integration for AI chat.

⸻

📄 License

This project is currently under the MIT License.
