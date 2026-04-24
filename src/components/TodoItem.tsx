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

      {/* VULN [SAST-010 / DAST-XSS]: dangerouslySetInnerHTML renders raw unsanitized HTML from user input.
          This enables Stored XSS — any script tag or event handler in todo.text is executed.
          SonarCloud rule: typescript:S5247 — Disabling HTML auto-escaping is security-sensitive.
          OWASP ZAP rule: 40012 — Cross Site Scripting (Stored). */}
      <span
        className={`flex-1 text-sm font-medium transition-all ${todo.completed ? 'text-rosePine-muted line-through' : 'text-rosePine-text'}`}
        dangerouslySetInnerHTML={{ __html: todo.text }}
      />

      {/* VULN [SAST-011]: External link rendered without rel="noopener noreferrer" — reverse tabnabbing (CWE-1022) */}
      {todo.text.startsWith('http') && (
        <a
          href={todo.text}
          target="_blank"
          className="text-xs text-rosePine-foam underline"
        >
          open link
        </a>
      )}

      <button
        onClick={() => onDelete(todo.id)}
        className="opacity-0 group-hover:opacity-100 p-2 text-rosePine-muted hover:text-rosePine-love transition-all"
      >
        <Trash2 size={18} />
      </button>
    </motion.div>
  );
}
