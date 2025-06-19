/**
 * Saga Pattern Implementation for Multi-Agent Orchestration
 * 
 * The Saga pattern manages distributed transactions across multiple agents
 * with automatic compensation on failure.
 */

import { EventEmitter } from 'events';
import { v4 as uuidv4 } from 'uuid';
import winston from 'winston';

export interface SagaStep {
  name: string;
  agent: string;
  action: string;
  compensationAction: string;
  retryable?: boolean;
  timeout?: number;
  input?: (context: SagaContext) => any;
  output?: (result: any, context: SagaContext) => void;
}

export interface SagaContext {
  sagaId: string;
  data: Record<string, any>;
  completedSteps: string[];
  failedStep?: string;
  error?: Error;
}

export interface SagaDefinition {
  name: string;
  steps: SagaStep[];
  timeout?: number;
  onSuccess?: (context: SagaContext) => void;
  onFailure?: (context: SagaContext) => void;
}

export class SagaOrchestrator extends EventEmitter {
  private logger: winston.Logger;
  private runningSegas: Map<string, SagaContext> = new Map();

  constructor() {
    super();
    
    this.logger = winston.createLogger({
      level: 'info',
      format: winston.format.json(),
      defaultMeta: { component: 'SagaOrchestrator' }
    });
  }

  /**
   * Execute a saga workflow
   */
  async execute(definition: SagaDefinition, initialData: any = {}): Promise<SagaContext> {
    const sagaId = uuidv4();
    const context: SagaContext = {
      sagaId,
      data: { ...initialData },
      completedSteps: []
    };

    this.runningSegas.set(sagaId, context);
    this.logger.info('Starting saga', { sagaId, name: definition.name });
    this.emit('saga:started', { sagaId, definition });

    try {
      // Execute steps in sequence
      for (const step of definition.steps) {
        await this.executeStep(step, context);
        context.completedSteps.push(step.name);
        
        this.emit('saga:step-completed', { 
          sagaId, 
          step: step.name,
          progress: context.completedSteps.length / definition.steps.length
        });
      }

      // Saga completed successfully
      this.logger.info('Saga completed successfully', { sagaId });
      
      if (definition.onSuccess) {
        await definition.onSuccess(context);
      }
      
      this.emit('saga:completed', { sagaId, context });
      
      return context;

    } catch (error: any) {
      // Saga failed - initiate compensation
      this.logger.error('Saga failed, starting compensation', { 
        sagaId, 
        failedStep: context.failedStep,
        error: error.message 
      });

      context.error = error;
      
      await this.compensate(definition, context);
      
      if (definition.onFailure) {
        await definition.onFailure(context);
      }
      
      this.emit('saga:failed', { sagaId, context });
      
      throw error;
      
    } finally {
      this.runningSegas.delete(sagaId);
    }
  }

  /**
   * Execute a single saga step
   */
  private async executeStep(step: SagaStep, context: SagaContext): Promise<void> {
    this.logger.info('Executing saga step', { 
      sagaId: context.sagaId, 
      step: step.name 
    });

    let attempts = 0;
    const maxAttempts = step.retryable ? 3 : 1;

    while (attempts < maxAttempts) {
      try {
        // Prepare input
        const input = step.input ? step.input(context) : context.data;

        // Execute action
        const result = await this.executeAction({
          agent: step.agent,
          action: step.action,
          input,
          timeout: step.timeout || 30000
        });

        // Process output
        if (step.output) {
          step.output(result, context);
        } else {
          context.data[step.name] = result;
        }

        return; // Success

      } catch (error: any) {
        attempts++;
        
        if (attempts >= maxAttempts) {
          context.failedStep = step.name;
          throw error;
        }

        // Retry with exponential backoff
        const delay = Math.pow(2, attempts - 1) * 1000;
        this.logger.warn('Step failed, retrying', { 
          sagaId: context.sagaId,
          step: step.name,
          attempt: attempts,
          delay 
        });
        
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  /**
   * Execute compensation logic for failed saga
   */
  private async compensate(definition: SagaDefinition, context: SagaContext): Promise<void> {
    // Compensate in reverse order
    const stepsToCompensate = [...context.completedSteps].reverse();

    for (const stepName of stepsToCompensate) {
      const step = definition.steps.find(s => s.name === stepName);
      if (!step) continue;

      try {
        this.logger.info('Compensating step', { 
          sagaId: context.sagaId, 
          step: stepName 
        });

        await this.executeAction({
          agent: step.agent,
          action: step.compensationAction,
          input: context.data,
          timeout: step.timeout || 30000
        });

        this.emit('saga:step-compensated', { 
          sagaId: context.sagaId, 
          step: stepName 
        });

      } catch (error) {
        this.logger.error('Compensation failed', { 
          sagaId: context.sagaId,
          step: stepName,
          error 
        });
        
        // Continue with other compensations
        this.emit('saga:compensation-failed', { 
          sagaId: context.sagaId, 
          step: stepName,
          error 
        });
      }
    }
  }

  /**
   * Execute an action on an agent (mock implementation)
   * In real implementation, this would communicate with actual agents
   */
  private async executeAction(params: {
    agent: string;
    action: string;
    input: any;
    timeout: number;
  }): Promise<any> {
    // This is where you'd integrate with your agent communication system
    // For example, using message bus or direct API calls
    
    this.emit('action:execute', params);
    
    // Simulate async action
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Mock response
    return {
      success: true,
      data: {
        ...params.input,
        processedBy: params.agent,
        action: params.action,
        timestamp: new Date()
      }
    };
  }

  /**
   * Get running sagas
   */
  getRunningSagas(): SagaContext[] {
    return Array.from(this.runningSegas.values());
  }

  /**
   * Cancel a running saga
   */
  async cancelSaga(sagaId: string): Promise<void> {
    const context = this.runningSegas.get(sagaId);
    if (!context) {
      throw new Error(`Saga not found: ${sagaId}`);
    }

    context.error = new Error('Saga cancelled by user');
    this.emit('saga:cancelled', { sagaId });
    
    // Trigger compensation
    // Implementation depends on your specific needs
  }
}

// Example saga definitions

export const orderProcessingSaga: SagaDefinition = {
  name: 'order-processing',
  steps: [
    {
      name: 'validate-order',
      agent: 'validation-agent',
      action: 'validate-order',
      compensationAction: 'mark-order-invalid',
      retryable: true,
      input: (ctx) => ({ orderId: ctx.data.orderId }),
      output: (result, ctx) => { ctx.data.validation = result; }
    },
    {
      name: 'reserve-inventory',
      agent: 'inventory-agent',
      action: 'reserve-items',
      compensationAction: 'release-items',
      retryable: true,
      input: (ctx) => ({ 
        items: ctx.data.items,
        orderId: ctx.data.orderId 
      })
    },
    {
      name: 'process-payment',
      agent: 'payment-agent',
      action: 'charge-payment',
      compensationAction: 'refund-payment',
      retryable: false,
      timeout: 60000,
      input: (ctx) => ({
        amount: ctx.data.totalAmount,
        paymentMethod: ctx.data.paymentMethod,
        orderId: ctx.data.orderId
      })
    },
    {
      name: 'create-shipment',
      agent: 'shipping-agent',
      action: 'create-shipment',
      compensationAction: 'cancel-shipment',
      retryable: true,
      input: (ctx) => ({
        orderId: ctx.data.orderId,
        address: ctx.data.shippingAddress,
        items: ctx.data.items
      })
    }
  ],
  timeout: 300000, // 5 minutes
  onSuccess: async (context) => {
    console.log('Order processed successfully:', context.sagaId);
    // Send confirmation email, update order status, etc.
  },
  onFailure: async (context) => {
    console.error('Order processing failed:', context.error);
    // Notify customer, log incident, etc.
  }
};

// Example usage
export async function demonstrateSagaPattern() {
  const orchestrator = new SagaOrchestrator();

  // Subscribe to events
  orchestrator.on('saga:started', ({ sagaId }) => {
    console.log(`Saga started: ${sagaId}`);
  });

  orchestrator.on('saga:step-completed', ({ step, progress }) => {
    console.log(`Step completed: ${step} (${(progress * 100).toFixed(0)}%)`);
  });

  orchestrator.on('saga:completed', ({ sagaId }) => {
    console.log(`Saga completed: ${sagaId}`);
  });

  orchestrator.on('saga:failed', ({ sagaId, context }) => {
    console.error(`Saga failed: ${sagaId}`, context.error);
  });

  try {
    // Execute order processing saga
    const result = await orchestrator.execute(orderProcessingSaga, {
      orderId: 'ORDER-123',
      items: [
        { sku: 'ITEM-1', quantity: 2, price: 29.99 },
        { sku: 'ITEM-2', quantity: 1, price: 49.99 }
      ],
      totalAmount: 109.97,
      paymentMethod: { type: 'credit_card', token: 'tok_123' },
      shippingAddress: {
        street: '123 Main St',
        city: 'Seattle',
        state: 'WA',
        zip: '98101'
      }
    });

    console.log('Saga result:', result);
    
  } catch (error) {
    console.error('Saga failed:', error);
  }
}

// Additional saga patterns

export const dataProcessingSaga: SagaDefinition = {
  name: 'data-processing-pipeline',
  steps: [
    {
      name: 'fetch-data',
      agent: 'data-fetcher',
      action: 'fetch-from-source',
      compensationAction: 'cleanup-temp-data',
      retryable: true
    },
    {
      name: 'validate-data',
      agent: 'validator',
      action: 'validate-schema',
      compensationAction: 'log-validation-failure',
      retryable: false
    },
    {
      name: 'transform-data',
      agent: 'transformer',
      action: 'apply-transformations',
      compensationAction: 'rollback-transformations',
      retryable: true
    },
    {
      name: 'store-data',
      agent: 'storage',
      action: 'persist-to-database',
      compensationAction: 'delete-stored-data',
      retryable: true
    }
  ]
};

export const mlTrainingSaga: SagaDefinition = {
  name: 'ml-model-training',
  steps: [
    {
      name: 'prepare-dataset',
      agent: 'data-prep-agent',
      action: 'prepare-training-data',
      compensationAction: 'cleanup-prepared-data',
      retryable: true,
      timeout: 600000 // 10 minutes
    },
    {
      name: 'train-model',
      agent: 'training-agent',
      action: 'train-ml-model',
      compensationAction: 'delete-model-artifacts',
      retryable: false,
      timeout: 3600000 // 1 hour
    },
    {
      name: 'evaluate-model',
      agent: 'evaluation-agent',
      action: 'evaluate-performance',
      compensationAction: 'log-evaluation-failure',
      retryable: true
    },
    {
      name: 'deploy-model',
      agent: 'deployment-agent',
      action: 'deploy-to-production',
      compensationAction: 'rollback-deployment',
      retryable: false
    }
  ]
};