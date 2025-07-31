# BLoC Implementation for Mercury Chat

This document explains the BLoC (Business Logic Component) implementation that replaces some functionality of the ChatProvider with a more structured state management approach.

## Overview

The BLoC implementation provides:

- **Separation of concerns**: Business logic is separated from UI
- **Reactive programming**: Using streams for state management
- **Testability**: Easy to unit test business logic
- **Predictable state**: Clear state transitions

## Structure

### 1. Message BLoC (`lib/bloc/message/`)

Handles all message-related operations:

- Loading messages for a conversation
- Sending messages
- Receiving real-time messages via WebSocket
- Typing indicators
- Message read status

**Events:**

- `LoadMessages`: Load messages for a conversation
- `SendMessage`: Send a new message
- `MessageReceived`: Handle incoming message from WebSocket
- `MarkMessageAsRead`: Mark a message as read
- `SendTyping`: Send typing indicator
- `TypingStatusChanged`: Handle typing status changes
- `ClearMessages`: Clear messages when leaving conversation

**States:**

- `MessageInitial`: Initial state
- `MessageLoading`: Loading messages
- `MessageLoaded`: Messages loaded successfully
- `MessageError`: Error occurred
- `MessageSending`: Sending a message
- `MessageSent`: Message sent successfully

### 2. Conversation BLoC (`lib/bloc/conversation/`)

Handles conversation management:

- Loading conversation list
- Creating new conversations
- Updating conversation metadata
- Muting/archiving conversations
- Real-time conversation updates

**Events:**

- `LoadConversations`: Load conversation list
- `CreateConversation`: Create new conversation
- `ConversationUpdated`: Handle conversation updates
- `ConversationDeleted`: Handle conversation deletion
- `MarkConversationAsRead`: Mark conversation as read
- `MuteConversation`: Mute/unmute conversation
- `ArchiveConversation`: Archive/unarchive conversation

**States:**

- `ConversationInitial`: Initial state
- `ConversationLoading`: Loading conversations
- `ConversationLoaded`: Conversations loaded
- `ConversationError`: Error occurred
- `ConversationCreating`: Creating new conversation
- `ConversationCreated`: Conversation created successfully

## Usage Examples

### 1. Setting up BLoC Providers

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<ConversationBloc>(
      create: (context) => ConversationBloc(),
    ),
    BlocProvider<MessageBloc>(
      create: (context) => MessageBloc(),
    ),
  ],
  child: MyApp(),
)
```

### 2. Loading Conversations

```dart
// Trigger loading
context.read<ConversationBloc>().add(LoadConversations());

// Listen to state changes
BlocBuilder<ConversationBloc, ConversationState>(
  builder: (context, state) {
    if (state is ConversationLoaded) {
      return ListView.builder(
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          return ConversationTile(conversation: state.conversations[index]);
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

### 3. Sending Messages

```dart
// Send a message
context.read<MessageBloc>().add(
  SendMessage(
    conversationId: 'conversation_id',
    content: 'Hello!',
    type: 'text',
  ),
);

// Listen for sending status
BlocListener<MessageBloc, MessageState>(
  listener: (context, state) {
    if (state is MessageSent) {
      // Message sent successfully
      print('Message sent: ${state.message.content}');
    } else if (state is MessageError) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error)),
      );
    }
  },
  child: ChatInterface(),
)
```

## Key Features

### Real-time Updates

Both BLoCs listen to WebSocket events and automatically update their state when:

- New messages arrive
- Conversations are updated
- Users start/stop typing
- Messages are read

### Error Handling

Each BLoC handles errors gracefully and emits appropriate error states that the UI can respond to.

### State Persistence

The BLoCs maintain state across screen navigation within the same session.

### Memory Management

BLoCs properly dispose of resources and unsubscribe from WebSocket events when no longer needed.

## Migrating from ChatProvider

To migrate from the existing ChatProvider:

1. **Replace Provider with BlocProvider** in your widget tree
2. **Convert Consumer widgets** to BlocBuilder/BlocListener
3. **Replace method calls** with event dispatching
4. **Update state access** to use BLoC states instead of provider getters

### Before (ChatProvider):

```dart
Consumer<ChatProvider>(
  builder: (context, chatProvider, child) {
    return Text('Messages: ${chatProvider.messages.length}');
  },
)

// Sending message
context.read<ChatProvider>().sendMessage(
  conversationId: 'id',
  content: 'Hello',
);
```

### After (BLoC):

```dart
BlocBuilder<MessageBloc, MessageState>(
  builder: (context, state) {
    if (state is MessageLoaded) {
      final messages = state.getMessagesForConversation('conversation_id');
      return Text('Messages: ${messages.length}');
    }
    return Text('Loading...');
  },
)

// Sending message
context.read<MessageBloc>().add(
  SendMessage(conversationId: 'id', content: 'Hello'),
);
```

## Benefits of BLoC Implementation

1. **Better Testing**: Business logic can be easily unit tested
2. **Clearer State Management**: Explicit states make debugging easier
3. **Separation of Concerns**: UI and business logic are clearly separated
4. **Reactive Programming**: Stream-based approach for real-time updates
5. **Scalability**: Easy to add new features and maintain existing ones
6. **Predictable**: State changes follow a clear pattern (Event → Business Logic → State)

## Files Created

- `lib/bloc/message/message_bloc.dart` - Message business logic
- `lib/bloc/message/message_event.dart` - Message events
- `lib/bloc/message/message_state.dart` - Message states
- `lib/bloc/conversation/conversation_bloc.dart` - Conversation business logic
- `lib/bloc/conversation/conversation_event.dart` - Conversation events
- `lib/bloc/conversation/conversation_state.dart` - Conversation states
- `lib/screens/chat_screen_bloc.dart` - BLoC-based chat screen
- `lib/screens/conversation_list_screen_bloc.dart` - BLoC-based conversation list
- `lib/apps/chat_app_bloc.dart` - Main app with BLoC providers

This implementation provides a solid foundation for managing chat functionality using the BLoC pattern while maintaining real-time capabilities through WebSocket integration.
