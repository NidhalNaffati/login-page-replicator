import { useState, useEffect } from 'react';
import { AnimatePresence } from 'framer-motion';
import { Plus, LogOut } from 'lucide-react';
import TodoItem, { type Todo } from './TodoItem';

interface TodoDashboardProps {
  onLogout: () => void;
}

export default function TodoDashboard({ onLogout }: TodoDashboardProps) {
  const [todos, setTodos] = useState<Todo[]>(() => {
    const saved = localStorage.getItem('todos');
    return saved ? JSON.parse(saved) : [];
  });
  const [inputValue, setInputValue] = useState('');

  useEffect(() => {
    localStorage.setItem('todos', JSON.stringify(todos));
  }, [todos]);

  const addTodo = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputValue.trim()) return;
    setTodos([{ id: Date.now(), text: inputValue.trim(), completed: false }, ...todos]);
    setInputValue('');
  };

  const toggleTodo = (id: number) => {
    setTodos(todos.map(t => t.id === id ? { ...t, completed: !t.completed } : t));
  };

  const deleteTodo = (id: number) => {
    setTodos(todos.filter(t => t.id !== id));
  };

  return (
    <div className="max-w-2xl mx-auto px-6 py-12 md:py-24">
      <nav className="flex items-center justify-between mb-12">
        <div>
          <h2 className="text-xl font-bold text-rosePine-text">My Tasks</h2>
          <p className="text-rosePine-muted text-sm tabular-nums">
            {todos.filter(t => !t.completed).length} pending
          </p>
        </div>
        <button
          onClick={onLogout}
          className="flex items-center gap-2 text-rosePine-muted hover:text-rosePine-love transition-colors text-sm font-medium"
        >
          <LogOut size={16} />
          Logout
        </button>
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
          onClick={addTodo}
          className="absolute right-3 top-1/2 -translate-y-1/2 p-2 bg-rosePine-pine text-rosePine-base rounded-lg hover:opacity-90 transition-opacity z-10"
        >
          <Plus size={20} />
        </button>
      </form>

      <div className="space-y-3">
        <AnimatePresence mode="popLayout">
          {todos.map((todo) => (
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
