import { MantineThemeOverride } from '@mantine/core';

export const theme: MantineThemeOverride = {
  colorScheme: 'dark',
  fontFamily: 'Inter',
  shadows: { sm: 'none', md: 'none', lg: 'none' },
  colors: {
    dark: [
      '#C1C2C5',
      '#A6A7AB',
      '#909296',
      '#5C5F66',
      '#373A40',
      '#2B2C3D',
      '#222222', // dark-6
      '#111111', // dark-7 - default background
      '#0a0a0a',
      '#000000',
    ]
  },
  components: {
    Button: {
      styles: {
        root: {
          border: 'none',
        },
      },
    },
    Notification: {
      styles: {
        root: {
          backgroundColor: '#111111',
          border: 'none',
          borderRadius: 4,
          boxShadow: 'none',
        },
        title: {
          color: '#ffffff',
          fontWeight: 600,
        },
        description: {
          color: 'rgba(255, 255, 255, 0.6)',
        }
      }
    },
    Progress: {
      styles: {
        root: {
          backgroundColor: '#222222',
          borderRadius: 0,
          height: 4,
        },
        bar: {
          borderRadius: 0,
        }
      }
    },
    Paper: {
      styles: {
        root: {
          backgroundColor: '#111111',
          border: 'none',
          borderRadius: 4,
          boxShadow: 'none',
        }
      }
    }
  },
};
