# Bubble Sort Visualizer in Pascal

A real-time visualization system for the bubble sort algorithm featuring a Pascal HTTP backend and responsive web frontend. This educational tool provides step-by-step algorithm execution tracking with interactive controls and visual feedback.

## Features

### Core Functionality
- **Real-time Algorithm Visualization**: Step-by-step execution of bubble sort with visual representation
- **Interactive Controls**: Play, pause, step forward/backward, and speed adjustment
- **Detailed Event Logging**: Comprehensive tracking of comparisons, swaps, and array states
- **RESTful API**: HTTP server providing JSON-based algorithm execution data


### Starting the System
1. **Start Backend**: Run the compiled Pascal executable
2. **Open Frontend**: Load `index.html` in a web browser
3. **Verify Connection**: Check that the status shows "Online"

## API Documentation

### Endpoints

#### `GET /test`
Returns bubble sort execution data for a predefined test array.

**Response**: JSON array of algorithm execution events

#### `POST /sort`
Processes a custom integer array through bubble sort algorithm.

**Request Body**:
```json
{
  "array": [64, 34, 25, 12, 22, 11, 90]
}
```

**Response**: JSON array of algorithm execution events

### Event Structure
Each algorithm step returns an event object:

```json
{
  "action": "compare|swap|init|finished",
  "step": 0,
  "compare_indices": [0, 1],
  "compare_values": [64, 34],
  "swap_indices": [0, 1],
  "swap_values": [34, 64],
  "is_swap": true,
  "array_state": "[34, 64, 25, 12, 22, 11, 90]"
}
```
