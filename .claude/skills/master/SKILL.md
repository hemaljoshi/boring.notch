---
name: master-prompt
description: Lightweight prompt optimizer using RTCROS framework with inline role specification. Use when the user starts their message with "master:" or "/master" followed by role and task.
---

# Master Prompt Optimizer (Lightweight)

This skill provides fast, token-efficient prompt optimization using the RTCROS framework with manual role specification.

## RTCROS Framework Components

1. **📌 Role**: Manually specified by the user
2. **🎯 Task**: Specific job and exact output wanted
3. **⚙️ Context**: Conversation history and user-provided details
4. **🧠 Reasoning**: Logical steps, validation checks, accuracy requirements
5. **✍️ Output Format**: Exact structure for response
6. **🛑 Stop Conditions**: When the task is officially complete

## When to Use

Use this skill when you want:
- **Token efficiency** - No project file analysis, minimal overhead
- **Role flexibility** - Specify any role: QA, Designer, DBA, DevOps, etc.
- **Quick optimization** - Fast prompt structuring without deep analysis
- **Cross-role tasks** - Easy to switch between different perspectives

## Usage Format

```
/master [Role] | [Task]
```

or

```
master: [Role] | [Task]
```

### Examples:
```
/master QA Engineer | write test cases for the login flow
/master UI/UX Designer | improve the onboarding screen design
/master Database Administrator | optimize slow queries
/master DevOps Engineer | set up CI/CD pipeline
/master Senior Backend Developer | add caching layer
```

## Instructions

Follow these steps exactly:

### Step 1: Parse the Input

Extract the role and task from the user's message:
- Format: `[Role] | [Task]`
- Split on the pipe (`|`) character
- Trim whitespace from both parts
- If no pipe found, ask user to provide role

### Step 2: Review Conversation Context

Quickly check the current conversation for:
- Relevant files or features discussed
- User preferences or constraints mentioned
- Previous decisions or patterns established

**Do NOT read project files** - keep it lightweight and fast.

### Step 3: Apply RTCROS Framework

Structure the request using the provided role and minimal context:

**Role**: Use exactly what the user provided

**Task**: Clarify and expand the task description
- Be specific about what needs to be done
- Define expected outputs

**Context**: Minimal, conversation-based only
- Any relevant discussion from current chat
- User-stated constraints or preferences
- No file analysis or project exploration

**Reasoning**: Define validation and logic
- Quality checks specific to the role
- Best practices for that role
- Decision-making criteria

**Output Format**: Specify exact deliverable structure

**Stop Conditions**: Clear completion criteria for the role

### Step 4: Present Optimized Prompt

Format your response like this:

```
📋 Original Request:
[Their original task]

👤 Assigned Role:
[Role they specified]

✨ Optimized RTCROS Prompt:

📌 Role: [User's specified role]

🎯 Task: [Clarified and expanded task]

⚙️ Context:
- [Conversation context if any]
- [User-stated constraints]
- [Minimal relevant details]

🧠 Reasoning:
- [Role-specific validation check 1]
- [Quality standard 2]
- [Best practice for this role]

✍️ Output Format:
[Exact format specification]

🛑 Stop Conditions:
[Clear completion criteria]

---

Does this capture what you want? Reply with:
- "yes" or "proceed" to continue
- corrections if needed
- "skip" to run without optimization
```

### Step 5: Wait for Confirmation

- **Do not proceed until the user confirms**
- If they correct you, update and ask again
- If they say "skip", proceed with original prompt
- Only execute after approval

### Step 6: Execute Using RTCROS Structure

Once confirmed:
- Use TodoWrite for multi-step tasks
- Maintain the specified role perspective
- Follow the reasoning criteria
- Deliver in the specified output format
- Stop when conditions are met

## Example Usage

**Example 1: QA Engineer Role**

**User writes:**
```
/master QA Engineer | create test plan for payment integration
```

**You respond:**
```
📋 Original Request:
create test plan for payment integration

👤 Assigned Role:
QA Engineer

✨ Optimized RTCROS Prompt:

📌 Role: QA Engineer specializing in payment systems and integration testing

🎯 Task: Create comprehensive test plan covering functional, security, and edge case testing for payment integration including test cases, test data requirements, and acceptance criteria

⚙️ Context:
- Payment integration feature (from request)
- Need to cover security and compliance
- Should include both positive and negative test scenarios
- Must validate error handling and edge cases

🧠 Reasoning:
- Verify all payment flows (successful, failed, pending, refunded)
- Validate security measures (PCI compliance, data encryption)
- Test edge cases (network failures, timeouts, invalid inputs)
- Ensure proper error messages and user feedback
- Check integration with existing systems

✍️ Output Format:
- Test plan document with sections:
  - Test scope and objectives
  - Test scenarios and cases
  - Test data requirements
  - Entry/exit criteria
  - Risk assessment

🛑 Stop Conditions:
- All payment scenarios are covered with test cases
- Security and compliance tests are included
- Edge cases and error scenarios are documented
- Test data requirements are clearly specified
- Plan is ready for stakeholder review

---

Does this capture what you want? Reply with "yes", corrections, or "skip"
```

**Example 2: UI/UX Designer Role**

**User writes:**
```
/master UI/UX Designer | redesign the dashboard for better data visualization
```

**You respond:**
```
📋 Original Request:
redesign the dashboard for better data visualization

👤 Assigned Role:
UI/UX Designer

✨ Optimized RTCROS Prompt:

📌 Role: UI/UX Designer specializing in data visualization and dashboard design

🎯 Task: Redesign dashboard with improved data visualization, focusing on information hierarchy, visual clarity, and user task flows while maintaining accessibility standards

⚙️ Context:
- Current dashboard needs better data visualization
- Users need to quickly understand key metrics
- Should maintain consistency with existing design system
- Must be accessible and responsive

🧠 Reasoning:
- Analyze current dashboard pain points and user needs
- Apply information hierarchy principles
- Use appropriate chart types for different data types
- Ensure color contrast meets WCAG AA standards
- Design for responsive layouts (mobile, tablet, desktop)
- Follow established design system patterns

✍️ Output Format:
- Design mockups (Figma/Sketch files or descriptions)
- Component specifications
- Interaction patterns
- Accessibility annotations
- Responsive breakpoint designs

🛑 Stop Conditions:
- Mockups clearly show improved information hierarchy
- Data visualizations are appropriate and clear
- Design meets accessibility standards
- Responsive layouts are provided
- Design system consistency is maintained

---

Does this capture what you want? Reply with "yes", corrections, or "skip"
```

**Example 3: Database Administrator Role**

**User writes:**
```
master: DBA | optimize database performance for reporting queries
```

**You respond:**
```
📋 Original Request:
optimize database performance for reporting queries

👤 Assigned Role:
DBA (Database Administrator)

✨ Optimized RTCROS Prompt:

📌 Role: Database Administrator specializing in query optimization and performance tuning

🎯 Task: Analyze and optimize slow reporting queries through indexing strategies, query rewrites, and database configuration tuning to achieve sub-second response times

⚙️ Context:
- Reporting queries are currently slow
- Need to improve query performance
- Should not impact transactional workload
- Production database requires careful optimization

🧠 Reasoning:
- Profile current queries to identify bottlenecks (EXPLAIN ANALYZE)
- Analyze table statistics and index usage
- Review execution plans for inefficient operations
- Identify missing indexes or unused indexes
- Check for N+1 query problems
- Validate changes don't degrade write performance
- Test optimizations in staging before production

✍️ Output Format:
- Performance analysis report
- Specific SQL query optimizations
- Index creation/modification scripts
- Configuration changes (if needed)
- Before/after performance metrics

🛑 Stop Conditions:
- Reporting queries execute in <1 second
- Indexes are properly utilized
- No degradation in write performance
- Changes tested in staging environment
- Monitoring shows improved query performance

---

Does this capture what you want? Reply with "yes", corrections, or "skip"
```

## Benefits of Master Skill

- **⚡ Fast**: No project file reads = minimal token usage
- **🎯 Flexible**: Use any role for any task
- **💡 Clear**: Simple syntax with pipe separator
- **🔄 Reusable**: Easy to switch roles for different perspectives
- **📊 Efficient**: ~90% fewer tokens than full project analysis

## Token Comparison

- **Full /opt skill**: ~5,500-9,000 tokens overhead
- **Master skill**: ~500-1,500 tokens overhead
- **Savings**: ~5,000-7,500 tokens per use

## Common Roles You Can Use

- **Development**: Frontend Developer, Backend Developer, Full-stack Developer, Mobile Developer
- **Quality**: QA Engineer, Test Automation Engineer, Performance Tester
- **Design**: UI/UX Designer, Visual Designer, Product Designer
- **Data**: Database Administrator, Data Engineer, Data Analyst, ML Engineer
- **Operations**: DevOps Engineer, Site Reliability Engineer, Security Engineer
- **Architecture**: Software Architect, Solutions Architect, Cloud Architect
- **Product**: Product Manager, Technical Writer, Business Analyst

## Important Notes

- **Role must be specified** - The skill requires the `[Role] | [Task]` format
- **No file analysis** - Keeps it lightweight; uses only conversation context
- **Use /opt for deep analysis** - When you need project exploration, use the full optimize skill
- **Perfect for cross-functional tasks** - Easily switch between QA, Design, Dev, etc.
- Always wait for confirmation before executing
