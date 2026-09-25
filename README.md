# 🏡 Home Sweet Home

**Home Sweet Home** is a cross-platform family management platform designed to help families coordinate everyday household activities through one connected digital workspace.

The platform brings together **family tasks, health reminders, shopping, finances, home maintenance, children, pets, and plants**, allowing information from different areas of family life to work together instead of being managed through separate applications.

The system is designed around a simple idea:

> **A home is not a list of individual responsibilities - it is a connected system where family members support one another.**

---

## Overview

Managing a household often involves many small activities happening at the same time - paying bills, completing household tasks, attending appointments, buying groceries, managing medications, taking children to tuition, maintaining plants, caring for pets, and keeping track of important family information.

**Home Sweet Home** aims to provide a centralized platform where family members can:

* Manage a shared family workspace
* Create, assign, and track household tasks
* Manage family health information and reminders
* Coordinate shopping and household purchases
* Keep track of household financial responsibilities
* Manage home maintenance activities
* Coordinate children's activities and responsibilities
* Manage pet-related activities
* Track plants and gardening activities
* Share relevant real-time family information when needed
* Receive reminders and notifications
* Explore AI-assisted family organization
* Keep information synchronized across different modules

The goal is to make household coordination **simpler, more collaborative, and less stressful**.

---

## Project Goals

Home Sweet Home is designed around the following goals:

### 1. Centralize Family Management

Bring commonly used household activities into a single platform rather than requiring family members to use multiple disconnected applications.

### 2. Encourage Shared Responsibility

Household activities should be treated as shared family responsibilities rather than being automatically assigned to one person.

### 3. Connect Different Household Modules

Information created in one module can contribute to other parts of the system.

For example:

* A medication reminder can appear in the global task system.
* A shopping requirement can be generated from a household need.
* A children's tuition activity can appear as a family task.
* A maintenance requirement can create a scheduled reminder.
* A pet or plant activity can become part of the household task workflow.

### 4. Support Different Family Members

The platform is designed to support different family members with different responsibilities, schedules, and needs.

### 5. Reduce Household Coordination Overhead

The application aims to make it easier for family members to understand:

**What needs to be done → Who is involved → When it needs to happen → What has already been completed.**

---

# Core Features

## Family Management

A shared family workspace where members can coordinate household activities.

### Features include:

* Family profile
* Family member profiles
* Member roles and permissions
* Shared family dashboard
* Family-specific settings
* Individual and family views
* Household activity visibility

The system is designed so that family members can maintain their own responsibilities while still participating in shared household activities.

---

## Smart Task Management

The task system acts as a central layer connecting different areas of the application.

### Task capabilities

* Create tasks
* Assign tasks to family members
* Set due dates
* Set priorities
* Track task status
* Mark tasks as completed
* View upcoming activities
* Track task history
* Display module-generated tasks

Tasks can originate from different modules while remaining accessible through the **global task system**.

### Example

A child has tuition on Saturday.

Instead of keeping the information only inside the Children module, the activity can also appear in the family's task/activity view.

---

## Family Health

The Health module is designed to help families organize important health-related information and reminders.

### Planned capabilities

* Personal health information
* Family health profiles
* Medication reminders
* Appointment reminders
* Health-related tasks
* Emergency information
* Important medical contacts
* Health history
* Medication availability reminders

The design focuses on making important information accessible to the appropriate family members while maintaining privacy.

---

## Shopping Management

The Shopping module helps families coordinate household purchases.

### Features

* Shared shopping lists
* Add and remove items
* Assign shopping responsibilities
* Track shopping status
* Categorize items
* Connect shopping requirements with household activities
* Maintain frequently purchased items

The system is designed around normal household shopping patterns rather than assuming that every item needs to be tracked individually by expiry.

---

## Family Money

The Money module provides a centralized space for household financial coordination.

### Planned capabilities

* Household expenses
* Shared bills
* Payment responsibilities
* Recurring expenses
* Family financial activities
* Expense history
* Financial reminders

Different family members can have different responsibilities rather than assuming that household expenses are always divided equally.

---

## Home Maintenance

The Maintenance module helps families keep track of activities required to maintain the home.

### Examples

* Electrical maintenance
* Plumbing
* Appliance servicing
* Cleaning activities
* Repairs
* Garden maintenance
* Scheduled maintenance
* Maintenance reminders

Maintenance activities can also be surfaced through the global task system.

---

## Children & Study Management

The Children module focuses on managing children's schedules and responsibilities.

### Examples

* Tuition classes
* School activities
* Assignments
* Pickup/drop-off activities
* Study reminders
* Important school events
* Parent responsibilities

Activities can be connected with the family's overall task and schedule system.

---

## Pet Management

The optional Pets module allows families to coordinate responsibilities related to household pets.

### Examples

* Feeding reminders
* Veterinary appointments
* Medication reminders
* Grooming
* Walk schedules
* Pet-related shopping
* Assigned responsibilities

---

## Plant & Garden Management

The Plants module allows families to manage household plants and gardening activities.

### Examples

* Watering schedules
* Fertilizing reminders
* Gardening tasks
* Plant information
* Plant care history
* Assigned family responsibilities

---

## Family Location & Coordination

The platform can support location-based family coordination where appropriate.

Potential use cases include:

* Knowing whether a family member is on the way home
* Coordinating school pickups
* Supporting shared family activities
* Improving emergency coordination

Location information is treated as sensitive family information and should only be accessible according to the application's privacy and permission rules.

---

## Notifications & Reminders

The system is designed to provide timely reminders for important household activities.

Examples include:

* Upcoming tasks
* Medication reminders
* Appointments
* Tuition
* Shopping requirements
* Maintenance activities
* Bill/payment reminders
* Pet care
* Plant care

---

# AI-Assisted Family Organization

Home Sweet Home is designed with the possibility of integrating AI assistance into the family management experience.

Potential AI-assisted capabilities include:

* Suggesting task schedules
* Helping organize family activities
* Summarizing upcoming household responsibilities
* Suggesting shopping items based on household needs
* Helping coordinate conflicting schedules
* Providing natural-language interaction with family information

AI features are intended to **assist family members**, not replace their decisions.

---

# Cross-Module Synchronization

One of the main architectural concepts of Home Sweet Home is **cross-module synchronization**.

The modules should not operate as isolated features.

For example:

```text
Health
   │
   ├── Medication Reminder
   │
   ▼
Global Tasks
   │
   ▼
Family Dashboard
```

Another example:

```text
Children
   │
   ├── Tuition
   ├── Assignment
   └── Pickup
          │
          ▼
     Global Tasks
          │
          ▼
    Family Dashboard
```

This approach allows information created in one part of the application to contribute to the overall family workflow.

---

# Application Modules

The planned module structure includes:

| Module             | Purpose                                         |
| ------------------ | ----------------------------------------------- |
| Family | Family members and shared household space       |
| Tasks            | Centralized household activities                |
| Health          | Health information, medication and appointments |
| Shopping        | Household shopping and purchasing               |
| Money           | Expenses, bills and financial responsibilities  |
| Maintenance     | Home repairs and maintenance                    |
| Children        | Children's activities and responsibilities      |
| Pets            | Pet care and related activities                 |
| Plants          | Plant and gardening management                  |
| Location        | Family location-based coordination              |
| Notifications   | Reminders and important updates                 |
| Settings        | Family and application configuration            |

Unused modules can be kept out of the primary navigation and made available through the **More** section when required.

---

# System Architecture

Home Sweet Home follows a separated frontend/backend architecture.

```text
┌──────────────────────────────────────────────┐
│              Flutter Application             │
│                                              │
│  Family │ Tasks │ Health │ Shopping │ Money  │
│  Children │ Pets │ Plants │ Maintenance      │
└──────────────────────┬───────────────────────┘
                       │
                  REST API
                       │
                       ▼
┌──────────────────────────────────────────────┐
│               Spring Boot API                │
│                                              │
│ Authentication │ Authorization │ Services    │
│ Controllers    │ Business Logic │ Validation │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│                    Database                  │
│                                              │
│ Users │ Families │ Tasks │ Health │ Finance  │
│ Shopping │ Children │ Pets │ Plants │ etc.   │
└──────────────────────────────────────────────┘
```

The architecture is designed to keep the presentation layer, backend business logic, and data persistence responsibilities separated.

---

# Technology Stack

## Frontend

* **Flutter**
* **Dart**
* Material Design
* REST API integration
* Responsive cross-platform UI

## Backend

* **Java**
* **Spring Boot**
* Spring Web
* Spring Security
* REST APIs
* Spring Data JPA
* Hibernate

## Database

The backend is designed to use a relational database for persistent application data.

Database configuration may vary depending on the development environment.

## Development & DevOps

* **Git**
* **GitHub**
* **Docker**
* REST API development
* API testing
* Environment-based configuration

---

# Security & Privacy

Because Home Sweet Home handles potentially sensitive family information, privacy and security are important design considerations.

The application is designed with concepts such as:

* Authentication
* Authorization
* Role-based access
* Secure API communication
* Password protection
* Controlled access to family information
* Environment-based secret configuration
* Separation of personal and shared information

Sensitive credentials and configuration values should **never be committed to the repository**.

For example:

```text
.env
application-local.properties
API keys
Database passwords
JWT secrets
```

should be excluded from version control where applicable.

---

# Docker

Docker is used to support a more consistent development environment and simplify deployment of backend services.

A typical development setup can be structured as:

```text
                 ┌─────────────────┐
                 │ Flutter Client  │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ Spring Boot API│
                 │    Container    │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │    Database     │
                 │    Container    │
                 └─────────────────┘
```

Docker configuration may differ depending on the current development stage of the project.

---

# Project Structure

```text
home-sweet-home/
│
├── frontend/
│   └── mobile/
│       ├── lib/
│       │   ├── core/
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── family/
│       │   │   ├── tasks/
│       │   │   ├── health/
│       │   │   ├── shopping/
│       │   │   ├── money/
│       │   │   ├── maintenance/
│       │   │   ├── children/
│       │   │   ├── pets/
│       │   │   └── plants/
│       │   └── main.dart
│       │
│       └── pubspec.yaml
│
├── backend/
│   └── src/
│       └── main/
│           ├── java/
│           └── resources/
│
├── docker/
│
├── README.md
└── .gitignore
```

> The exact directory structure may change as development progresses.

---

# Getting Started

## Prerequisites

Make sure the following tools are installed:

* Flutter SDK
* Dart SDK
* JDK 17 or later
* Maven
* Git
* Docker
* A relational database or Docker-based database environment
* Android Studio or another Flutter-compatible development environment

---

## 1. Clone the Repository

```bash
git clone https://github.com/GPCThushani/home-sweet-home.git
```

Navigate into the project:

```bash
cd home-sweet-home
```

---

# Frontend Setup

Navigate to the Flutter application:

```bash
cd frontend/mobile
```

Install dependencies:

```bash
flutter pub get
```

Check the Flutter environment:

```bash
flutter doctor
```

Run the application:

```bash
flutter run
```

For Android development, make sure an emulator or physical Android device is connected.

---

# Backend Setup

Navigate to the backend:

```bash
cd backend
```

Build the project:

```bash
mvn clean install
```

Run the Spring Boot application:

```bash
mvn spring-boot:run
```

The backend API will then be available according to the configured server port.

---

# Docker Setup

If Docker configuration is provided in the project, the required services can be started using:

```bash
docker compose up --build
```

To run the services in the background:

```bash
docker compose up -d --build
```

To stop the services:

```bash
docker compose down
```

---

# Environment Configuration

Configuration values should be provided through environment-specific configuration rather than hard-coded into the source code.

Example:

```text
DATABASE_URL=
DATABASE_USERNAME=
DATABASE_PASSWORD=
JWT_SECRET=
API_BASE_URL=
```

Create the appropriate local configuration according to the environment used for development.

**Do not commit real credentials or secrets to GitHub.**

---

# API Architecture

The backend exposes RESTful APIs that allow the Flutter application to communicate with the server.

A simplified request flow is:

```text
Flutter App
     │
     │ HTTP Request
     ▼
Spring Boot Controller
     │
     ▼
Service Layer
     │
     ▼
Repository Layer
     │
     ▼
Database
     │
     ▼
JSON Response
     │
     ▼
Flutter App
```

This separation helps maintain a clear distinction between:

* UI responsibilities
* API handling
* Business logic
* Data access
* Persistence

---

# Example Household Workflow

A typical household workflow can look like this:

```text
Family Member
      │
      ▼
Creates / Receives Activity
      │
      ▼
Module
(Health / Children / Shopping / Maintenance)
      │
      ▼
Global Task System
      │
      ▼
Assigned Family Member
      │
      ▼
Reminder / Notification
      │
      ▼
Task Completed
      │
      ▼
Activity History Updated
```

This provides a connected experience instead of treating each module as an independent application.

---

# Design Principles

Home Sweet Home follows a friendly and practical design approach.

### Calm & Friendly Interface

The application avoids an overly technical or corporate appearance and aims to create a comfortable environment suitable for everyday family use.

### Simple Navigation

Frequently used activities should remain easy to access while less frequently used modules can be organized under the **More** section.

### Family-Centered Design

The interface focuses on the family as a group while still respecting individual responsibilities and privacy.

### Inclusive Interaction

The system is designed to accommodate family members with different levels of technical familiarity.

### Connected Experiences

Information should flow between modules when there is a meaningful relationship rather than forcing users to enter the same information repeatedly.

---

# Privacy Considerations

Home Sweet Home may handle information such as:

* Family member profiles
* Health information
* Medication reminders
* Financial information
* Household schedules
* Location information
* Children's activities

Therefore, privacy should be considered throughout the system.

Important principles include:

* Collect only necessary information
* Restrict access according to permissions
* Protect authentication credentials
* Avoid exposing private information unnecessarily
* Secure communication between application and backend
* Avoid storing secrets in source control

---

# Development Status

**Home Sweet Home is currently under active development.**

The project is being developed incrementally, with the architecture and core modules evolving throughout the development process.

### Current development focus

* [x] Initial project architecture
* [x] Flutter application foundation
* [x] Spring Boot backend foundation
* [x] Core family-management concept
* [x] Global task-management concept
* [x] Modular household architecture
* [ ] Authentication and authorization
* [ ] Family management
* [ ] Health module
* [ ] Shopping module
* [ ] Money module
* [ ] Maintenance module
* [ ] Children module
* [ ] Pets module
* [ ] Plants module
* [ ] Cross-module synchronization
* [ ] Notifications
* [ ] Location-based features
* [ ] AI-assisted features
* [ ] Production deployment

> The checklist reflects the planned development roadmap and may change as implementation progresses.

---

# Future Improvements

Potential future enhancements include:

* Advanced family scheduling
* Intelligent task recommendations
* AI-powered household assistant
* Smart recurring-task generation
* Calendar integration
* Advanced notification rules
* Offline-first functionality
* Conflict resolution for offline changes
* More granular family permissions
* Cloud deployment
* Analytics dashboards
* Enhanced accessibility
* Multi-language support
* Family activity insights

---

# Project Context

Home Sweet Home is developed as a practical software engineering project with a focus on applying full-stack development concepts to a real-world household coordination problem.

The project provides practical experience in:

* Cross-platform application development
* REST API development
* Backend architecture
* Database design
* Authentication and authorization
* State management
* Modular application architecture
* API integration
* Docker-based development
* Git and GitHub workflows
* Privacy-aware application design
* Scalable system design

---

# Author

**G.P.C. Thushani**

Information Systems Undergraduate
Department of Computing & Information Systems
Sabaragamuwa University of Sri Lanka

### Areas of Interest

* Full Stack Development
* Cloud Computing
* Mobile Application Development
* Web Development
* Artificial Intelligence

---

# Project Status

**Status:** In Development

Home Sweet Home is an evolving project. Features, architecture, and implementation details may change as development continues.

---

## Support

If you find this project interesting, consider giving the repository a ⭐ on GitHub.

---

## License

This project is developed for educational and portfolio purposes.

License information will be added when the project is formally licensed.
