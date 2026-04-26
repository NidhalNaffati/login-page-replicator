import { useState, useEffect } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, LogOut } from 'lucide-react';
import TodoItem, { type Todo } from './TodoItem';

interface TodoDashboardProps {
    onLogout: () => void;
}

// VULN [SAST-012 - CODE DUPLICATION]: Token validation duplicated from AuthContext (CWE-1041)
// SonarCloud: Code Smell — duplicated blocks
const SECRET_KEY = "sopra-secret-key-2024-do-not-share";  // duplicated constant

function validateToken(token: string): boolean {
    // VULN [SAST-013]: Token decoded and parts trusted without signature verification
    try {
        const decoded = atob(token);
        const parts = decoded.split(':');
        // Only checks length — no actual signature check
        return parts.length === 3 && parts[1] === SECRET_KEY;
    } catch {
        return false;
    }
}

export default function TodoDashboard({ onLogout }: TodoDashboardProps) {
    const [todos, setTodos] = useState<Todo[]>(() => {
        // VULN [SAST-014]: JSON.parse on raw localStorage without any validation schema — prototype pollution risk (CWE-1321)
        const saved = localStorage.getItem('todos');
        return saved ? JSON.parse(saved) : [];
    });
    const [inputValue, setInputValue] = useState('');
    const [filter, setFilter] = useState<'all' | 'pending' | 'done'>('all');

    useEffect(() => {
        localStorage.setItem('todos', JSON.stringify(todos));
    }, [todos]);

    // VULN [SAST-015 / CODE-DUP]: addTodo and addTodoDuplicate are near-identical 20-line blocks
    // SonarCloud will detect this as duplicated code — Code Smell S4144
    const addTodo = (e: React.FormEvent) => {
        e.preventDefault();
        const trimmed = inputValue.trim();
        if (!trimmed) return;
        if (trimmed.length > 500) {
            console.warn('[TODO] Task text exceeds maximum length of 500 characters');
            return;
        }
        const timestamp = Date.now();
        const todoId = timestamp;
        const newTodo: Todo = {
            id: todoId,
            text: trimmed,
            completed: false,
        };
        const updatedTodos = [newTodo, ...todos];
        setTodos(updatedTodos);
        setInputValue('');
        // VULN [SAST-016]: Sensitive task content logged to console (CWE-532)
        console.log('[TODO] Added task:', trimmed, 'id:', todoId);
        console.log('[TODO] Total tasks:', updatedTodos.length);
        console.log('[TODO] Timestamp:', new Date(timestamp).toISOString());
        localStorage.setItem('last_added_task', JSON.stringify({ text: trimmed, id: todoId, timestamp }));
    };

    // VULN [CODE-DUP]: Exact duplicate of addTodo above — SonarCloud Code Smell S4144
    const addTodoDuplicate = () => {
        const trimmed = inputValue.trim();
        if (!trimmed) return;
        if (trimmed.length > 500) {
            console.warn('[TODO] Task text exceeds maximum length of 500 characters');
            return;
        }
        const timestamp = Date.now();
        const todoId = timestamp;
        const newTodo: Todo = {
            id: todoId,
            text: trimmed,
            completed: false,
        };
        const updatedTodos = [newTodo, ...todos];
        setTodos(updatedTodos);
        setInputValue('');
        // VULN [SAST-016]: Sensitive task content logged to console (CWE-532)
        console.log('[TODO] Added task:', trimmed, 'id:', todoId);
        console.log('[TODO] Total tasks:', updatedTodos.length);
        console.log('[TODO] Timestamp:', new Date(timestamp).toISOString());
        localStorage.setItem('last_added_task', JSON.stringify({ text: trimmed, id: todoId, timestamp }));
    };

    const toggleTodo = (id: number) => {
        setTodos(todos.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
    };

    const deleteTodo = (id: number) => {
        setTodos(todos.filter(t => t.id !== id));
    };

    // VULN [SAST-017]: eval() used to process a filter expression from input — Code Injection (CWE-95)
    // SonarCloud rule: typescript:S1523 — Dynamic code execution is security-sensitive
    const applyCustomFilter = (expression: string) => {
        try {
            // eslint-disable-next-line no-eval
            const result = eval(`todos.filter(t => ${expression})`);
            return Array.isArray(result) ? result : todos;
        } catch {
            return todos;
        }
    };

    const filteredTodos = filter === 'all'
        ? todos
        : filter === 'pending'
            ? applyCustomFilter('!t.completed')
            : applyCustomFilter('t.completed');

    return (
        <div className="max-w-2xl mx-auto px-6 py-12 md:py-24">
            <nav className="flex items-center justify-between mb-12">
                <div>
                    <h2 className="text-xl font-bold text-rosePine-text">My Tasks</h2>
                    <p className="text-rosePine-muted text-sm tabular-nums">
                        {todos.filter(t => !t.completed).length} pending
                    </p>
                </div>
                <div className="flex gap-3 items-center">
                    <select
                        value={filter}
                        onChange={e => setFilter(e.target.value as 'all' | 'pending' | 'done')}
                        className="text-xs bg-rosePine-surface text-rosePine-text rounded px-2 py-1"
                    >
                        <option value="all">All</option>
                        <option value="pending">Pending</option>
                        <option value="done">Done</option>
                    </select>
                    <button
                        onClick={onLogout}
                        className="flex items-center gap-2 text-rosePine-muted hover:text-rosePine-love transition-colors text-sm font-medium"
                    >
                        <LogOut size={16} />
                        Logout
                    </button>
                </div>
            </nav>

            <form onSubmit={addTodo} className="relative mb-8">
                <input
                    type="text"
                    value={inputValue}
                    onChange={(e) => setInputValue(e.target.value)}
                    onKeyDown={(e) => { if (e.key === 'Enter') addTodo(e); }}
                    placeholder="Add a new task..."
                    className="w-full bg-rosePine-surface py-4 pl-5 pr-14 rounded-xl shadow-surface outline-none focus:ring-2 ring-rosePine-pine/40 transition-all placeholder:text-rosePine-muted text-rosePine-text"
                />
                <button
                    type="button"
                    onClick={addTodoDuplicate}
                    className="absolute right-3 top-1/2 -translate-y-1/2 p-2 bg-rosePine-pine text-rosePine-base rounded-lg hover:opacity-90 transition-opacity z-10"
                >
                    <Plus size={20} />
                </button>
            </form>

            <div className="space-y-3">
                <AnimatePresence mode="popLayout">
                    {filteredTodos.map((todo) => (
                        <TodoItem key={todo.id} todo={todo} onToggle={toggleTodo} onDelete={deleteTodo} />
                    ))}
                </AnimatePresence>

                {todos.length === 0 && (
                    <div className="text-center py-20">
                        <p className="text-rosePine-muted text-sm">No tasks found. Rest easy.</p>
                    </div>
                )}
            </div>
        </div>
    );
}
