# Tragar CMS - Quote Management System Plan

## High-Level Goal
Build a modern business dashboard for managing quotes from the Tragar API with real-time updates and clean CRUD operations.

## Detailed Steps

- [x] Generate Phoenix LiveView project `tragar_cms` with SQLite
- [x] Create plan.md and start server for live development
- [ ] Replace default home page with static mockup of modern business dashboard
  - Dark professional theme with sidebar navigation
  - Quote management interface with table view
  - Form for adding new quotes
  - Dashboard cards showing quote statistics
- [ ] Create Quote schema with Ecto
  - Fields: id, content, author, source, category, status, inserted_at, updated_at
  - Basic validations for required fields
- [ ] Build QuotesLive LiveView module
  - List all quotes with real-time updates via PubSub
  - Handle form submission for creating quotes
  - Handle quote deletion and status updates
- [ ] Create quotes_live.html.heex template
  - Modern dashboard layout with sidebar
  - Quote table with actions (edit, delete, status toggle)
  - Quote creation form with validation
  - Statistics cards at top
- [ ] Add TragarApi client module (stubbed initially)
  - Module for future API integration
  - Stub methods for fetching quotes from Tragar
- [ ] Update layouts to match modern business dashboard design
  - Dark theme with professional color scheme
  - Remove default Phoenix header/nav
  - Force dark theme in root.html.heex
- [ ] Update router with quotes route as root
  - Replace placeholder home route with quotes LiveView
  - Add quotes route to browser pipeline
- [ ] Visit running app to verify all functionality works

## Reserved Steps
- 1 step reserved for debugging unexpected issues

Total: 10 steps planned
