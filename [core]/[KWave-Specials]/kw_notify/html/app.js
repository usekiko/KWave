// DTF Notify - Notification Manager

const container = document.getElementById('notification-container');

// No icons - clean circular progress only
const icons = {
    success: '',
    error: '',
    warning: '',
    info: ''
};

// GTA Color codes to CSS colors
const gtaColors = {
    '0': '#000000',      // Black
    '1': '#FF0000',      // Red
    '2': '#00FF00',      // Green
    '3': '#FFFF00',      // Yellow
    '4': '#0000FF',      // Blue
    '5': '#00FFFF',      // Cyan/Light Blue
    '6': '#FF00FF',      // Purple/Magenta
    '7': '#FFFFFF',      // White (default)
    '8': '#FF4444',      // Dark Red
    '9': '#4444FF',      // Dark Blue
};

// Convert GTA color codes (^1, ^2, etc.) to HTML
function parseColorCodes(text) {
    if (!text) return '';
    
    // Escape HTML first (prevent XSS)
    const escaped = text
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
    
    // Split by color codes and build HTML
    const parts = escaped.split(/(\^\d)/g);
    let result = '';
    let currentColor = null;
    let buffer = '';
    
    for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        
        if (part.match(/^\^\d$/)) {
            // This is a color code
            const colorCode = part.charAt(1);
            
            // Close previous color span if open
            if (currentColor && buffer) {
                result += `<span style="color: ${currentColor}">${buffer}</span>`;
                buffer = '';
            } else if (buffer) {
                result += buffer;
                buffer = '';
            }
            
            // Set new color (or null for ^7 white/default)
            currentColor = colorCode === '7' ? null : (gtaColors[colorCode] || null);
        } else {
            // Regular text
            buffer += part;
        }
    }
    
    // Don't forget the last buffer
    if (currentColor && buffer) {
        result += `<span style="color: ${currentColor}">${buffer}</span>`;
    } else {
        result += buffer;
    }
    
    return result;
}

// Active notifications
let notifications = [];
let idCounter = 0;

// Create notification
function createNotification(data) {
    const id = ++idCounter;
    const duration = data.duration || 5000;
    const type = data.type || 'info';
    const title = data.title || getDefaultTitle(type);
    const description = data.description || '';
    const icon = data.icon || icons[type] || icons.info;
    
    // Parse color codes
    const parsedTitle = parseColorCodes(title);
    const parsedDescription = parseColorCodes(description);
    
    // Create element
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.id = `notification-${id}`;
    
    // SVG circular progress - circumference of circle with r=10.5 is ~66
    const svgProgress = `
        <svg class="circular-progress" viewBox="0 0 24 24">
            <circle class="circular-progress-bg" cx="12" cy="12" r="10.5"/>
            <circle class="circular-progress-fill" cx="12" cy="12" r="10.5" style="animation-duration: ${duration}ms;"/>
        </svg>
    `;
    
    notification.innerHTML = `
        <div class="notification-icon-wrap">
            ${svgProgress}
            <div class="notification-icon">${icon}</div>
        </div>
        <div class="notification-content">
            <div class="notification-title">${parsedTitle}</div>
            <div class="notification-description">${parsedDescription}</div>
        </div>
    `;
    
    // Add to container
    container.appendChild(notification);
    
    // Store reference
    const notifData = {
        id: id,
        element: notification,
        timeout: null
    };
    notifications.push(notifData);
    
    // Auto remove
    notifData.timeout = setTimeout(() => {
        removeNotification(id);
    }, duration);
    
    // Click to dismiss
    notification.addEventListener('click', () => {
        removeNotification(id);
    });
    
    return id;
}

// Remove notification
function removeNotification(id) {
    const index = notifications.findIndex(n => n.id === id);
    if (index === -1) return;
    
    const notif = notifications[index];
    
    // Clear timeout
    if (notif.timeout) {
        clearTimeout(notif.timeout);
    }
    
    // Add exit animation
    notif.element.classList.add('removing');
    
    // Remove from DOM after animation
    setTimeout(() => {
        if (notif.element.parentNode) {
            notif.element.parentNode.removeChild(notif.element);
        }
    }, 300);
    
    // Remove from array
    notifications.splice(index, 1);
}

// Get default title based on type
function getDefaultTitle(type) {
    switch(type) {
        case 'success': return 'Success';
        case 'error': return 'Error';
        case 'warning': return 'Warning';
        default: return 'Information';
    }
}

// Sound player function
function playNotificationSound(type, silent, customSound) {
    if (silent) return; // Skip sound if silent mode
    
    // Handle custom sound (e.g., 'announcement')
    if (customSound) {
        const customAudio = document.getElementById('sound-' + customSound);
        if (customAudio) {
            customAudio.currentTime = 0;
            customAudio.volume = 0.6;
            customAudio.play().catch(e => {
                console.log('[^7DTF Notify^7] Custom sound play failed:', e);
            });
            return;
        }
    }
    
    const soundMap = {
        success: 'sound-success',
        error: 'sound-error',
        warning: 'sound-warning',
        info: 'sound-info'
    };
    
    const soundId = soundMap[type] || 'sound-info';
    const audio = document.getElementById(soundId);
    
    if (audio) {
        audio.currentTime = 0;
        audio.volume = 0.5;
        audio.play().catch(e => {
            // Ignore autoplay errors (browsers block audio until user interaction)
            console.log('[^7DTF Notify^7] Sound play failed (autoplay policy):', e);
        });
    }
}

// Listen for Lua messages
window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'notify') {
        createNotification(data.data);
        playNotificationSound(data.data.type || 'info', data.data.silent, data.data.sound);
    }
});

// Console log
console.log('[^7DTF Notify^7] NUI loaded');
