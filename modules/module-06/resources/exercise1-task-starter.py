"""
Task Model Module

This module defines the Task model for our task management system.
Use Pydantic for data validation and serialization.

Requirements:
- Task should have: id, title, description, status, created_at, updated_at, priority
- Status should be an enum with values: TODO, IN_PROGRESS, DONE
- Priority should be an integer between 1 and 5
- Dates should be automatically set

Copilot Prompt Suggestion:
# Create a Pydantic Task model with:
# - id field using UUID with factory default
# - title as required string with min length 1
# - description as optional string
# - status as enum (TODO, IN_PROGRESS, DONE) 
# - created_at and updated_at as datetime with defaults
# - priority as int between 1-5, default 3
# Include model config for JSON serialization
"""

# TODO: Import necessary modules
# Hint: You'll need pydantic, uuid, datetime, enum, and typing

# TODO: Create TaskStatus enum

# TODO: Create Task model class
