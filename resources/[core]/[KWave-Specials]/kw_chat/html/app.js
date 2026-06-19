// KW Chat - Enhanced Client JavaScript
// Improved animations, reliability, and error handling

(function() {
    'use strict';

    // DOM Elements
    const elements = {
        container: document.getElementById('chat-container'),
        messagesArea: document.getElementById('messages-area'),
        messagesList: document.getElementById('messages-list'),
        inputArea: document.getElementById('input-area'),
        chatInput: document.getElementById('chat-input'),
        suggestionsBox: document.getElementById('suggestions-box'),
        suggestionsList: document.getElementById('suggestions-list')
    };

    // State
    const state = {
        isInputActive: false,
        chatVisible: false,
        messageHistory: [],
        historyIndex: -1,
        currentSuggestions: [],
        selectedSuggestionIndex: -1,
        allSuggestions: new Map(),
        hideTimeout: null,
        maxMessages: 100,
        maxHistory: 50,
        hideDelay: 6000
    };

    // Resource name cache
    let resourceName = null;
    function getResourceName() {
        if (resourceName) return resourceName;
        const path = window.location.pathname;
        const match = path.match(/\/([^/]+)\/html/);
        resourceName = match ? match[1] : 'kw_chat';
        return resourceName;
    }

    // Safe fetch wrapper
    async function sendNUI(event, data = {}) {
        try {
            await fetch(`https://${getResourceName()}/${event}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data)
            });
        } catch (e) {
            console.error('[^6KW Chat^7] NUI Error:', e);
        }
    }

    // Show/Hide Chat Window
    function showChat() {
        if (!state.chatVisible) {
            state.chatVisible = true;
            elements.container.classList.remove('hidden');
        }
        resetHideTimer();
    }

    function hideChat() {
        if (!state.isInputActive && state.chatVisible) {
            state.chatVisible = false;
            elements.container.classList.add('hidden');
        }
    }

    function resetHideTimer() {
        if (state.hideTimeout) {
            clearTimeout(state.hideTimeout);
            state.hideTimeout = null;
        }
        if (state.chatVisible && !state.isInputActive) {
            state.hideTimeout = setTimeout(hideChat, state.hideDelay);
        }
    }

    // Open/Close Input
    function openChat() {
        state.isInputActive = true;
        state.chatVisible = true;
        elements.container.classList.remove('hidden');
        elements.inputArea.classList.remove('hidden');
        elements.chatInput.value = '';
        elements.chatInput.focus();
        clearTimeout(state.hideTimeout);
        state.hideTimeout = null;
    }

    function closeChat() {
        state.isInputActive = false;
        elements.inputArea.classList.add('hidden');
        elements.suggestionsBox.classList.add('hidden');
        state.currentSuggestions = [];
        state.selectedSuggestionIndex = -1;
        resetHideTimer();
    }

    // Escape HTML
    function escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // Parse GTA color codes
    function parseColorCodes(text) {
        if (!text) return '';
        const colors = {
            '0': '#000000', '1': '#FF0000', '2': '#00FF00', '3': '#FFFF00',
            '4': '#0000FF', '5': '#00FFFF', '6': '#FF00FF', '7': '#FFFFFF',
            '8': '#FF4444', '9': '#4444FF'
        };
        
        let result = '';
        let currentColor = null;
        const parts = text.split(/(\^\d)/g);
        
        for (const part of parts) {
            if (part.match(/^\^\d$/)) {
                const code = part.charAt(1);
                if (currentColor) result += '</span>';
                currentColor = code === '7' ? null : (colors[code] || null);
                if (currentColor) result += `<span style="color:${currentColor}">`;
            } else {
                result += escapeHtml(part);
            }
        }
        if (currentColor) result += '</span>';
        return result;
    }

    // Get message type from content
    function getMessageType(message) {
        const text = (message.args?.[1] || message.message || '').toLowerCase();
        const author = (message.args?.[0] || message.author || '').toLowerCase();
        
        if (author === 'admin' || author === 'system' || text.includes('admin')) return 'admin';
        if (text.includes('error') || text.includes('invalid') || text.includes('unknown')) return 'error';
        if (author === '' || text.includes('joined') || text.includes('left')) return 'system';
        return 'normal';
    }

    // Add Message
    function addMessage(message) {
        if (!message) return;

        const msgType = getMessageType(message);
        const messageEl = document.createElement('div');
        messageEl.className = `message ${msgType}`;

        let author = 'Unknown';
        let text = '';
        let color = [255, 255, 255];

        if (message.args && Array.isArray(message.args)) {
            if (message.args.length >= 2) {
                author = message.args[0];
                text = message.args[1];
            } else if (message.args.length === 1) {
                text = message.args[0];
            }
        } else {
            author = message.author || 'System';
            text = message.message || '';
        }

        if (message.color && Array.isArray(message.color)) {
            color = message.color;
        }

        const timestamp = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        const typeLabel = msgType === 'normal' ? 'Chat' : msgType;
        const colorCss = `rgb(${color[0]}, ${color[1]}, ${color[2]})`;

        messageEl.innerHTML = `
            <div class="message-header">
                <span class="message-type" style="color: ${colorCss}">${typeLabel}</span>
                <span class="message-author">${escapeHtml(author)}</span>
                <span class="message-time">${timestamp}</span>
            </div>
            <div class="message-text">${parseColorCodes(text)}</div>
        `;

        elements.messagesList.appendChild(messageEl);

        // Limit messages with smooth removal
        while (elements.messagesList.children.length > state.maxMessages) {
            const first = elements.messagesList.firstChild;
            first.classList.add('fading');
            setTimeout(() => first?.remove(), 300);
        }

        // Auto scroll
        requestAnimationFrame(() => {
            elements.messagesArea.scrollTo({
                top: elements.messagesArea.scrollHeight,
                behavior: 'smooth'
            });
        });
    }

    // Clear Chat
    function clearChat() {
        elements.messagesList.innerHTML = '';
        state.messageHistory = [];
        state.historyIndex = -1;
    }

    // Suggestions Management
    function addSuggestion(suggestion) {
        if (!suggestion?.name) return;
        const existing = state.allSuggestions.get(suggestion.name);
        if (existing) {
            existing.help = suggestion.help || existing.help;
            existing.params = suggestion.params || existing.params;
        } else {
            state.allSuggestions.set(suggestion.name, {
                name: suggestion.name,
                help: suggestion.help || '',
                params: suggestion.params || []
            });
        }
    }

    function removeSuggestion(name) {
        state.allSuggestions.delete(name);
    }

    // Update Suggestions Display
    function updateSuggestions(query) {
        if (!query || query.length < 1) {
            elements.suggestionsBox.classList.add('hidden');
            state.currentSuggestions = [];
            return;
        }

        const q = query.toLowerCase();
        const matches = [];

        for (const [name, cmd] of state.allSuggestions) {
            const lowerName = name.toLowerCase();
            if (lowerName === q) {
                matches.unshift({ ...cmd, score: 3 });
            } else if (lowerName.startsWith(q)) {
                matches.push({ ...cmd, score: 2 });
            } else if (lowerName.includes(q)) {
                matches.push({ ...cmd, score: 1 });
            }
        }

        matches.sort((a, b) => b.score - a.score);
        state.currentSuggestions = matches.slice(0, 8);
        state.selectedSuggestionIndex = -1;

        if (state.currentSuggestions.length === 0) {
            elements.suggestionsBox.classList.add('hidden');
            return;
        }

        elements.suggestionsList.innerHTML = '';
        state.currentSuggestions.forEach((suggestion, index) => {
            const item = document.createElement('div');
            item.className = 'suggestion-item';
            item.dataset.index = index;

            const params = suggestion.params?.map(p => `[${p.name}]`).join(' ') || '';
            const fullCommand = '/' + suggestion.name + (params ? ' ' + params : '');
            
            item.innerHTML = `
                <div class="suggestion-content">
                    <span class="suggestion-cmd">${escapeHtml(fullCommand)}</span>
                    <span class="suggestion-desc">${escapeHtml(suggestion.help || 'No description')}</span>
                </div>
            `;

            item.addEventListener('click', () => selectSuggestion(index));
            elements.suggestionsList.appendChild(item);
        });

        elements.suggestionsBox.classList.remove('hidden');
    }

    function updateSelection() {
        const items = elements.suggestionsList.querySelectorAll('.suggestion-item');
        items.forEach((item, index) => {
            if (index === state.selectedSuggestionIndex) {
                item.classList.add('selected');
                item.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
            } else {
                item.classList.remove('selected');
            }
        });
    }

    function selectSuggestion(index) {
        if (index < 0 || index >= state.currentSuggestions.length) return;
        const suggestion = state.currentSuggestions[index];
        elements.chatInput.value = '/' + suggestion.name + ' ';
        elements.chatInput.focus();
        elements.suggestionsBox.classList.add('hidden');
    }

    // Send Message
    function sendMessage() {
        const text = elements.chatInput.value.trim();
        
        sendNUI('chatResult', { 
            message: text, 
            canceled: text.length === 0 
        });

        if (text.length > 0) {
            state.messageHistory.push(text);
            if (state.messageHistory.length > state.maxHistory) {
                state.messageHistory.shift();
            }
            state.historyIndex = state.messageHistory.length;
        }

        elements.chatInput.value = '';
        elements.suggestionsBox.classList.add('hidden');
    }

    // Event Listeners
    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data?.type) return;

        switch (data.type) {
            case 'ON_MESSAGE':
                addMessage(data.message);
                showChat();
                break;
            case 'ON_SHOW':
                showChat();
                break;
            case 'ON_OPEN':
                openChat();
                break;
            case 'ON_CLOSE':
                closeChat();
                break;
            case 'ON_CLEAR':
                clearChat();
                break;
            case 'ON_SUGGESTION_ADD':
                addSuggestion(data.suggestion);
                break;
            case 'ON_SUGGESTION_REMOVE':
                removeSuggestion(data.name);
                break;
        }
    });

    // Input Events
    elements.chatInput.addEventListener('input', () => {
        const value = elements.chatInput.value;
        if (value.startsWith('/')) {
            updateSuggestions(value.substring(1));
        } else {
            elements.suggestionsBox.classList.add('hidden');
        }
    });

    elements.chatInput.addEventListener('keydown', (e) => {
        // Enter to send
        if (e.key === 'Enter') {
            e.preventDefault();
            sendMessage();
            return;
        }

        // Escape to cancel
        if (e.key === 'Escape') {
            e.preventDefault();
            sendNUI('chatResult', { message: '', canceled: true });
            return;
        }

        // History navigation
        if (state.currentSuggestions.length === 0) {
            if (e.key === 'ArrowUp') {
                e.preventDefault();
                if (state.historyIndex > 0) {
                    state.historyIndex--;
                    elements.chatInput.value = state.messageHistory[state.historyIndex] || '';
                }
                return;
            }
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                if (state.historyIndex < state.messageHistory.length - 1) {
                    state.historyIndex++;
                    elements.chatInput.value = state.messageHistory[state.historyIndex] || '';
                } else {
                    state.historyIndex = state.messageHistory.length;
                    elements.chatInput.value = '';
                }
                return;
            }
        }

        // Suggestion navigation
        if (state.currentSuggestions.length > 0) {
            if (e.key === 'ArrowDown') {
                e.preventDefault();
                state.selectedSuggestionIndex = Math.min(
                    state.selectedSuggestionIndex + 1, 
                    state.currentSuggestions.length - 1
                );
                updateSelection();
                return;
            }
            if (e.key === 'ArrowUp') {
                e.preventDefault();
                state.selectedSuggestionIndex = Math.max(state.selectedSuggestionIndex - 1, -1);
                updateSelection();
                return;
            }
            if (e.key === 'Tab' && state.selectedSuggestionIndex >= 0) {
                e.preventDefault();
                selectSuggestion(state.selectedSuggestionIndex);
                return;
            }
        }
    });

    // Click outside to close suggestions
    document.addEventListener('click', (e) => {
        if (!e.target.closest('#suggestions-box') && !e.target.closest('#chat-input')) {
            elements.suggestionsBox.classList.add('hidden');
        }
    });

    // Initialize
    elements.container.classList.add('hidden');
    sendNUI('loaded', {});
    
    console.log('[^6KW Chat^7] Enhanced Edition loaded');
})();
