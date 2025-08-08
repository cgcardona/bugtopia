# 🔍 SwiftUI State Violation Debugging Setup

## 🚨 Get Full Stack Traces for "Modifying state during view update" Errors

### Method 1: Xcode Environment Variables (MOST EFFECTIVE)

1. **Open Scheme Editor**:
   - Product → Scheme → Edit Scheme...
   - Select "Run" in the left sidebar
   - Go to "Arguments" tab

2. **Add Environment Variables**:
   ```
   Name: SWIFTUI_DEBUG_MODIFIER_CHANGES
   Value: 1
   
   Name: SWIFTUI_DEBUG_BODY_EVALUATION
   Value: 1
   
   Name: SWIFTUI_DEBUG_STATE_MUTATION
   Value: 1
   
   Name: LIBSWIFTUI_DEBUG_MODIFIER_CHANGES
   Value: 1
   ```

3. **Enable Additional SwiftUI Debugging**:
   ```
   Name: _LIBSWIFTUI_DEBUG_PRINT_CHANGES
   Value: 1
   
   Name: _LIBSWIFTUI_DEBUG_VIEW_UPDATES
   Value: 1
   ```

### Method 2: Symbolic Breakpoint for State Mutations

1. **Open Breakpoint Navigator** (⌘+8)
2. **Click "+" → "Symbolic Breakpoint"**
3. **Set Symbol**:
   ```
   -[_SwiftUI_ModifiedContent updateStateFromObservation:]
   ```
4. **Add Action**: "Log Message" with:
   ```
   State violation detected: %H
   ```
5. **Check "Automatically continue after evaluating actions"**

### Method 3: Runtime State Violation Breakpoint

Add another symbolic breakpoint:
```
Symbol: SwiftUI._printChanges()
Action: Log Message: "SwiftUI state change detected"
Condition: Leave blank
```

### Method 4: Advanced Console Debugging

Add to your scheme's environment variables:
```
Name: OS_ACTIVITY_MODE
Value: disable

Name: IDEPreferLogStreaming
Value: YES
```

This will give cleaner console output for debugging.
