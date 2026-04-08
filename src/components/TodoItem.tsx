import { motion } from 'framer-motion';
import { CheckCircle2, Circle, Trash2 } from 'lucide-react';

export interface Todo {
  id: number;
  text: string;
  completed: boolean;
}

interface TodoItemProps {
  todo: Todo;
  onToggle: (id: number) => void;
  onDelete: (id: number) => void;
}

export default function TodoItem({ todo, onToggle, onDelete }: TodoItemProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      layout
      className="group flex items-center gap-4 bg-rosePine-surface p-4 rounded-xl shadow-surface hover:shadow-surface-hover transition-all"
    >
      <button
        onClick={() => onToggle(todo.id)}
        className={`transition-colors ${todo.completed ? 'text-rosePine-foam' : 'text-rosePine-muted group-hover:text-rosePine-subtle'}`}
      >
        {todo.completed ? <CheckCircle2 size={22} /> : <Circle size={22} />}
      </button>

      {/* VULN: Intentional XSS — dangerouslySetInnerHTML renders raw HTML from user input */}
      <span
        className={`flex-1 text-sm font-medium transition-all ${todo.completed ? 'text-rosePine-muted line-through' : 'text-rosePine-text'}`}
        dangerouslySetInnerHTML={{ __html: todo.text }}
      />

      <button
        onClick={() => onDelete(todo.id)}
        className="opacity-0 group-hover:opacity-100 p-2 text-rosePine-muted hover:text-rosePine-love transition-all"
      >
        <Trash2 size={18} />
      </button>
    </motion.div>
  );
}
